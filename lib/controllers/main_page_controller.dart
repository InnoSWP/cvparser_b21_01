import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cvparser_b21_01/datatypes/export.dart';
import 'package:cvparser_b21_01/services/key_listener.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class MainPageController extends GetxController {
  final keyLookup = Get.find<KeyListener>();

  /// Using lazy approach, we will initially upload cv's as [NotParsedCV],
  /// but on the first invocation it converts them to the [ParsedCV].

  // map unique file index -> selectable file
  bool _blockCvs = false;
  final cvsS = <int, Selectable<CVBase>>{}.obs;
  final _current = Rxn<int>();

  int? selectPoint;

  // subscribe to the stream of key events
  late StreamSubscription<dynamic> _escListener;

  late StreamSubscription<dynamic> _delListener;
  // the cvs by itself needs to be protected, so only _parseCv should be
  // able to change cvs at any time (needed for parallelization purposes,
  // so it's important to check is it accessable on every invocation)
  RxMap<int, Selectable<CVBase>>? get cvs => _blockCvs ? null : cvsS;

  /// Creates native dialog for user to select files
  Future<void> askUserToUploadPdfFiles() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"], // TESTIT: what if not pdf
      allowMultiple: true,
      withReadStream: true,
      withData: false,
      lockParentWindow: true,
    );

    // if cvs is not blocked and there is some input
    if (picked != null && cvs != null) {
      for (PlatformFile file in picked.files) {
        // add an NotParsedCV
        cvs![cvs!.length] = Selectable(
          item: RawPdfCV(
            // just because it's web, we cannot store file path,
            // but we can get stream of filedata
            filename: file.name,
            readStream: file.readStream,
          ),
          isSelected: false,
        );
      }
    }
  }

  /// Tries to delete selected, if cvs is blocked - does nothing
  void deleteSelected() {
    // Note: the whole expression is wrapped like this
    // only because it's synchronus function
    if (cvs != null) {
      var remaining = <int, Selectable<CVBase>>{};
      for (var cv in cvs!.entries) {
        if (!cv.value.isSelected) {
          remaining[cv.key] = cv.value;
        }
      }
      cvs!.value = remaining;
      selectPoint = null;
    }
  }

  /// Tries to deselect all, if cvs is blocked - does nothing
  void deselectAll() {
    // Note: the whole expression is wrapped like this
    // only because it's synchronus function
    if (cvs != null) {
      for (var cv in cvs!.values) {
        cv.isSelected = false;
      }
      cvs!.refresh();
    }
  }

  /// Try to export selected, blocking cvs during the process
  /// if the cvs was blocked, it would throw AlreadyInProcess
  Future<void> exportSelected() async {
    if (cvs != null) {
      // as for now only exportSelected can block cvs
      throw AlreadyInProcess();
    }

    _blockCvs = true;
    // so I blocked cvs for others, but here I can acess it by cvsS
    {
      // TODO (export multiple/one): (in UI) cover by popup
      // (so cvs must be persist throughout the whole export process)
      for (var index in cvsS.keys) {
        var cv = cvsS[index]!;
        if (cv.isSelected) {
          // if cv is not parsed => parse cv (with exception check)
          // TODO (export multiple/one): json serializable
          if (cv.item is NotParsedCV) {
            bool notParsed = true;
            while (notParsed) {
              try {
                await _parseCv(index);
                notParsed = false;
              } on AlreadyInProcess {
                // we can only poll it's status
                // if it was scheduled somewhere else
                //
                // Note: actually we can store and further pull
                // instances of futures that are working
                // _parseCv invocations, but it would be more complex
                // but it would be more complex
                await Future.delayed(const Duration(milliseconds: 50));
              }
            }
            print(json.encode(cv.item));
          }
        }
      }
    }
    _blockCvs = false;
  }

  @override
  void onClose() async {
    await _escListener.cancel();
    await _delListener.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    _escListener = keyLookup.escEventStream.listen((event) {
      if (event == KeyEventType.down) {
        deselectAll();
      }
    });
    _delListener = keyLookup.delEventStream.listen((event) {
      if (event == KeyEventType.down) {
        deleteSelected();
      }
    });
    super.onInit();
  }

  /// Switches select of cv,
  /// if there is no such index, or the cvs is blocked - does nothing
  void select(int index) {
    if (cvs != null && cvs![index] != null) {
      cvs![index]!.isSelected = true;
      cvs!.refresh();
    }
  }

  /// Tries to select all, if cvs is blocked - does nothing
  void selectAll() {
    // Note: the whole expression is wrapped like this
    // only because it's synchronus function
    if (cvs != null) {
      for (var cv in cvs!.values) {
        cv.isSelected = true;
      }
      cvs!.refresh();
    }
  }

  /// Provided [index] (in cvs list) of the cv that you need to display parsed,
  /// this function tries to set the [_current] to that index
  /// and starts asynchronous parsing of that CV
  ///
  /// - ignored if there is no such index
  void setCurrent(int index) {
    // ya, here we can directly query cvsS itself
    if (cvsS[index] != null) {
      // display current immediately
      _current.value = index;

      // run parsing future
      // Note: ignore if it's already in process
      _parseCv(index).onError<AlreadyInProcess>((error, stackTrace) {});
    }
  }

  /// Switches select of cv,
  /// if there is no such index, or the cvs is blocked - does nothing
  void switchSelect(int index) {
    if (cvs != null && cvs![index] != null) {
      cvs![index]!.isSelected = !cvs![index]!.isSelected;
      // here `Rx` knows only that we invoked getter of list,
      // but did not know what did we do with the element itself
      // so from the point of view of `Rx` it was just a lookup,
      // so to notify that it was not just a lookup, we need to set it manually
      cvs!.refresh();
    }
  }

  /// This function will create a future that will:
  /// 1. take the element at index
  /// 2. try to parse it (this may throw an exception)
  /// 3. try to store the procession result into the same index
  ///
  /// Note: because of the third point it's important for files
  /// to persist the same immutable unique identifier [index],
  /// even after some manipulations on [cvs]
  /// (for example - deletions from cvs should not affect index of remaining)
  ///
  /// - will throw an AlreadyInProcess exception if you call it without
  /// waiting for completion of the first invocation on the same [index]
  ///
  /// will do nothing if:
  /// - there is no element with such index (check at point 1)
  /// - the index element was already parsed (check at point 1)
  /// - there is no element with such index after (check at point 3)
  Future<void> _parseCv(int index) async {
    // ya, only this function can work with cvsS directly
    if (cvsS[index] != null) {
      var tmp = cvsS[index]!.item;

      // The lazy approach itself
      if (tmp is NotParsedCV) {
        cvsS[index]!.item = CVBase(tmp.filename); // mark it as processing
        try {
          // 5 TODO (uploading cv): special popup if iExtract API is not working
          cvsS[index]?.item = await tmp.parse(); // some async code
        } catch (e) {
          cvsS[index]?.item = tmp; // so it's not processing anymore
          rethrow;
        }
      } else if (tmp is ParsedCV) {
        // it was already converted, so there is nothing to do
      } else {
        // Note that if we entered here, then the type of tmp is CVBase,
        // which is the indicator that someone is now working on it.
        throw AlreadyInProcess();
      }
    }
  }

  // TODO (export one): export by one
}
import 'parsed/cv_match.dart';
import 'parsed/parsed_cv.dart';
import "package:test/test.dart";

import 'search.dart';

ParsedCV createBetterParsedCV(String filename, List<String> labels,
    List<List<String>> matches, List<List<String>> sentences) {
  var map = Map<String, List<CVMatch>>();
  for (var j = 0; j < labels.length; j++) {
    var tmp = <CVMatch>[];
    for (var i = 0; i < matches[j].length; i++) {
      CVMatch cur = CVMatch(match: matches[j][i], sentence: sentences[j][i]);
      tmp.add(cur);
    }

    map.putIfAbsent(labels[j], () => tmp);
  }
  return ParsedCV(filename: filename, data: map);
}

List<ParsedCV> getTestCVs() {
  var tests = <ParsedCV>[];
  tests.add(createBetterParsedCV("file1", [
    "CsSkill",
    "Language"
  ], [
    ["java", "c#"],
    ["Russian", "English"]
  ], [
    ["I programm on java", "I am quite professional in C#"],
    ["I know fluent Russian and English", "I know fluent Russian and English"]
  ]));

  tests.add(createBetterParsedCV("file2", [
    "CsSkill",
    "Language",
    "Education"
  ], [
    ["flutter", "python"],
    ["English", "Indonesian"],
    ["Java university", "Skillbox"]
  ], [
    ["I programm on java", "I am quite professional in C#"],
    ["I know fluent Russian", "I know fluent Russian"],
    ["R", "R"]
  ]));

  tests.add(createBetterParsedCV("file3", [
    "CsSkill",
    "Language",
    "Org"
  ], [
    ["go", "dart"],
    ["English", "German"],
    ["Microsoft", "Google"]
  ], [
    ["go is my favourite language", "I am quite professional in dart"],
    ["I know fluent English", "German is my native"],
    ["R", "R"]
  ]));

  tests.add(createBetterParsedCV("file4", [
    "CsSkill",
    "Education",
    "Country"
  ], [
    ["Java", "1c"],
    ["Irkutsk state university"],
    ["Russia"]
  ], [
    ["go is my favourite language", "I am quite professional in dart"],
    ["I know fluent English", "German is my native"],
    ["R"]
  ]));

  tests.add(createBetterParsedCV("file5", [
    "CsSkill",
    "softSkill",
    "emails"
  ], [
    ["React", "JavaScript"],
    ["agile", "scum"],
    ["aboba@gmail.com"]
  ], [
    ["React is my favourite language", "I am quite professional in JavaScript"],
    ["agile is my life", "I am scum master"],
    ["aboba@gmail.com is my email"]
  ]));

  return tests;
}

List<String> getFileNames(List<ParsedCV> a) {
  var output = <String>[];
  for (var elem in a) {
    output.add(elem.filename);
  }
  return output;
}

int main() {
  var testCVs = getTestCVs();

  print(getFileNames(filterCVs(testCVs, "sentence: scum master")));

  test("filter match in specific label ", () {
    expect(getFileNames(filterCVs(testCVs, "label: csskill match: java")),
        ["file1", "file4", "file5"]);
  });

  test("filter with logical or '|'", () {
    expect(getFileNames(filterCVs(testCVs, "match: java | label: emails")),
        ["file1", "file2", "file4", "file5"]);
  });

  test("specific search with logical & (and)", () {
    expect(
        getFileNames(filterCVs(testCVs,
            "label: CsSkill match: flutter & label: language match: english")),
        ["file2"]);
  });

  test("filename search", () {
    expect(getFileNames(filterCVs(testCVs, "filename: file")),
        ["file1", "file2", "file3", "file4", "file5"]);
  });

  // test("sentence search", () {
  //   expect(
  //       getFileNames(filterCVs(testCVs, "sentence: scum master")), ["file5"]);
  // });
  return 0;
}

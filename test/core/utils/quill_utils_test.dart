import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendix/core/utils/quill_utils.dart';

void main() {
  group('QuillUtils', () {
    group('documentFromNotesString', () {
      test('null input returns empty document', () {
        final doc = QuillUtils.documentFromNotesString(null);
        expect(QuillUtils.isDocumentEmpty(doc), isTrue);
      });

      test('empty string returns empty document', () {
        final doc = QuillUtils.documentFromNotesString('');
        expect(QuillUtils.isDocumentEmpty(doc), isTrue);
      });

      test('whitespace-only string returns empty document', () {
        final doc = QuillUtils.documentFromNotesString('   ');
        expect(QuillUtils.isDocumentEmpty(doc), isTrue);
      });

      test('Quill Delta JSON array format', () {
        final json = jsonEncode([
          {'insert': 'Hello World\n'}
        ]);
        final doc = QuillUtils.documentFromNotesString(json);
        expect(doc.toPlainText(), 'Hello World\n');
        expect(QuillUtils.isDocumentEmpty(doc), isFalse);
      });

      test('Quill Delta JSON array with formatting', () {
        final json = jsonEncode([
          {
            'insert': 'Bold text',
            'attributes': {'bold': true}
          },
          {'insert': '\n'}
        ]);
        final doc = QuillUtils.documentFromNotesString(json);
        expect(doc.toPlainText(), 'Bold text\n');
      });

      test('Quill Delta JSON object format with ops key', () {
        final json = jsonEncode({
          'ops': [
            {'insert': 'Object format\n'}
          ]
        });
        final doc = QuillUtils.documentFromNotesString(json);
        expect(doc.toPlainText(), 'Object format\n');
      });

      test('plain text fallback', () {
        final doc = QuillUtils.documentFromNotesString('Just plain text');
        expect(doc.toPlainText().trim(), 'Just plain text');
        expect(QuillUtils.isDocumentEmpty(doc), isFalse);
      });

      test('plain text with special characters', () {
        final doc = QuillUtils.documentFromNotesString('Ümlauts & Sönderzeichen: äöü');
        expect(doc.toPlainText().trim(), 'Ümlauts & Sönderzeichen: äöü');
      });
    });

    group('notesStringFromDocument', () {
      test('empty document returns null', () {
        final doc = Document();
        expect(QuillUtils.notesStringFromDocument(doc), isNull);
      });

      test('document with content returns JSON string', () {
        final doc = Document()..insert(0, 'Test content');
        final result = QuillUtils.notesStringFromDocument(doc);
        expect(result, isNotNull);

        // Verify it's valid JSON
        final decoded = jsonDecode(result!);
        expect(decoded, isList);
        expect(decoded.length, greaterThan(0));
      });
    });

    group('isDocumentEmpty', () {
      test('new Document is empty', () {
        expect(QuillUtils.isDocumentEmpty(Document()), isTrue);
      });

      test('document with content is not empty', () {
        final doc = Document()..insert(0, 'Content');
        expect(QuillUtils.isDocumentEmpty(doc), isFalse);
      });
    });

    group('round-trip conversion', () {
      test('Document → JSON → Document preserves content', () {
        final original = Document()..insert(0, 'Round trip test');
        final json = QuillUtils.notesStringFromDocument(original);
        expect(json, isNotNull);

        final restored = QuillUtils.documentFromNotesString(json);
        expect(restored.toPlainText(), original.toPlainText());
      });

      test('formatted Document → JSON → Document preserves formatting', () {
        final deltaJson = [
          {
            'insert': 'Bold',
            'attributes': {'bold': true}
          },
          {'insert': ' and '},
          {
            'insert': 'italic',
            'attributes': {'italic': true}
          },
          {'insert': '\n'}
        ];
        final json = jsonEncode(deltaJson);
        final doc = QuillUtils.documentFromNotesString(json);
        final serialized = QuillUtils.notesStringFromDocument(doc);
        final restoredDoc = QuillUtils.documentFromNotesString(serialized);

        expect(restoredDoc.toPlainText(), 'Bold and italic\n');
      });
    });
  });
}

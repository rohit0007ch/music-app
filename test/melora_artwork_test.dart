import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';

void main() {
  testWidgets('falls back to gradient when imageUrl is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MeloraArtwork(paletteIndex: 0, size: 48)),
      ),
    );

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('falls back when file artwork is missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeloraArtwork(
            paletteIndex: 1,
            size: 48,
            imageUrl: 'file:///tmp/melora_missing_art_does_not_exist.jpg',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('ignores unsupported content:// artwork URIs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeloraArtwork(
            paletteIndex: 0,
            size: 48,
            imageUrl: 'content://media/external/audio/albumart/1',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uses network Image for https artwork URLs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeloraArtwork(
            paletteIndex: 3,
            size: 48,
            imageUrl: 'https://example.com/cover.jpg',
          ),
        ),
      ),
    );
    // Do not pumpAndSettle — network image never completes in unit tests.
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back for empty imageUrl strings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeloraArtwork(paletteIndex: 0, size: 48, imageUrl: '  '),
        ),
      ),
    );
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

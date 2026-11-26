import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/core/widgets/swipe_delete_tile.dart';
import 'package:grain_video/data/db/repositories.dart';
import 'package:grain_video/features/me/pages/watch_history_page.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('左滑删除观看历史条目，列表与数据库同步移除', (tester) async {
    final repo = WatchHistoryRepository(db);
    await repo.saveProgress(
      sourcePackage: 'com.example.fake',
      bangumiUrl: 'https://example.com/1',
      title: '测试番剧',
      episodeUrl: 'ep-1',
      episodeTitle: '第1集',
      positionMs: 60000,
      durationMs: 600000,
    );
    await repo.saveProgress(
      sourcePackage: 'com.example.fake',
      bangumiUrl: 'https://example.com/2',
      title: '另一部番',
      episodeUrl: 'ep-2',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: 'assets/l10n',
                fallbackFile: 'zh',
                useCountryCode: false,
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh')],
          home: const WatchHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试番剧'), findsOneWidget);
    expect(find.text('另一部番'), findsOneWidget);

    // 左滑「另一部番」→ 露出删除按钮（不直接删）。
    await tester.timedDrag(
      find.text('另一部番'),
      const Offset(-500, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('另一部番'), findsOneWidget);

    // 点「另一部番」那行的红色删除按钮 → 二次确认框。
    // （每行都常驻一个隐藏删除按钮，需锚定到目标行。）
    final tile = find.ancestor(
      of: find.text('另一部番'),
      matching: find.byType(SwipeDeleteTile),
    );
    await tester.tap(find.descendant(of: tile, matching: find.text('删除')));
    await tester.pumpAndSettle();
    // 确认框为 app_dialog 的 Dialog 范式（帧 86:247），非 AlertDialog。
    expect(find.byType(Dialog), findsOneWidget);

    // 确认后移除，列表与数据库同步。
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(find.text('另一部番'), findsNothing);
    expect(find.text('测试番剧'), findsOneWidget);
    expect((await repo.recent()).length, 1);
  });

  testWidgets('左滑后点取消，条目保留', (tester) async {
    final repo = WatchHistoryRepository(db);
    await repo.saveProgress(
      sourcePackage: 'com.example.fake',
      bangumiUrl: 'https://example.com/1',
      title: '测试番剧',
      episodeUrl: 'ep-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: 'assets/l10n',
                fallbackFile: 'zh',
                useCountryCode: false,
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh')],
          home: const WatchHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.timedDrag(
      find.text('测试番剧'),
      const Offset(-500, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('测试番剧'), findsOneWidget);
    expect((await repo.recent()).length, 1);
  });
}

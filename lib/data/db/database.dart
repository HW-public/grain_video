import 'package:drift/drift.dart';

/// 数据层骨架（Phase 3 建表）。
///
/// 当前无表，仅保留 @DriftDatabase 注解锚点，保证依赖与代码路径可用。
/// 表结构（历史记录、追番、扩展安装信息等）在 Phase 3 定义，
/// 定义后运行 build_runner 生成 _$AppDatabase 混入。
@DriftDatabase(tables: [])
class AppDatabase {
  // 迁移框架约定（Phase 3 实施）：
  // - schemaVersion 从 1 开始，每次表结构变更 +1；
  // - 迁移写在 onUpgrade 的 MigrationStrategy 中，禁止Destructive；
  // - 新增表先写 Table 类，再升 schemaVersion，再补 onUpgrade 分支。
}

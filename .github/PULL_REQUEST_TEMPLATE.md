## 变更

- 解决的问题：
- 用户可见结果：
- 失败与降级路径：

## 验证证据

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze --fatal-infos`
- [ ] 非 golden 测试
- [ ] `python3 .github/scripts/verify_visual_benchmarks.py`
- [ ] Android release 构建、最终 APK guards 与 crash-symbol 归档（涉及平台或发布时）
- [ ] iOS device `--release --no-codesign`、打包隐私/许可与 dSYM UUID 门禁（涉及平台或发布时）

测试命令、设备、系统版本和结果：

## UI、无障碍与性能

- [ ] 手机核心任务在 360×800、375×667、393×852 内单屏完成，无纵向滚动
- [ ] 提供目标尺寸截图；golden 变化附 before / after / diff
- [ ] 检查 200% 字号、读屏语义、48dp 触控区、减少动态和高对比
- [ ] 没有用整屏 PNG、截图切片或颜色单独表达状态

不适用说明：

## Clean-room / provenance

- Public specifications consulted:
- Related GPL source viewed by implementer: yes / no
- Why this implementation is independent:
- Third-party code/assets/models/data:
- Licenses, redistribution rights, versions and hashes verified:

## 风险

- 隐私 / 安全：
- 数据或模型偏差：
- 公共接口 / 持久化 / 协议：
- 仍未解决：

#pragma once

#include <QObject>

// 输入服务（最小版）：提供 KeyBindChip 所需的键名映射。
// 手柄/鼠标侧键捕获在播放器场景不需要：setListening 为空实现，tokenCaptured 保留声明不触发。
class InputService : public QObject
{
    Q_OBJECT
public:
    explicit InputService(QObject* parent = nullptr);

    // Qt 键码 → 存储名（逐行移植 BallsHackPro InputUtils::keyCodeToName）
    Q_INVOKABLE QString keyToString(int qtKey);
    // 键盘监听态开关（空实现，保持 KeyBindChip 调用不报错）
    Q_INVOKABLE void setListening(bool on);

signals:
    // 手柄/侧键捕获（本版本不触发）
    void tokenCaptured(const QString& token);
};

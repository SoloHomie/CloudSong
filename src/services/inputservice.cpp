#include "inputservice.h"

InputService::InputService(QObject* parent)
    : QObject(parent)
{
}

void InputService::setListening(bool on)
{
    Q_UNUSED(on)
}

// ── Qt 键码 → 显示名 ────────────────────────────────────
// 逐行移植 BallsHackPro InputUtils::keyCodeToName (2026-08-26):
// 输出必须与旧 QML 完全一致, 保证存储名 → QKeySequence 往返解析不变。
QString InputService::keyToString(int key)
{
    // 字母 A-Z (0x41-0x5A)
    if (key >= 0x41 && key <= 0x5A) return QString(QChar(key));
    // 数字 0-9 (0x30-0x39)
    if (key >= 0x30 && key <= 0x39) return QString(QChar(key));
    // 上档字符 → 降级到基础键名 (Shift+1 绑定为 "1"; 存 "!" 键码映射表
    // 没有它 → 绑定无效 2026-08-23)
    switch (key) {
        case 0x21: return "1";  case 0x40: return "2";  case 0x23: return "3";
        case 0x24: return "4";  case 0x25: return "5";  case 0x5E: return "6";
        case 0x26: return "7";  case 0x2A: return "8";  case 0x28: return "9";
        case 0x29: return "0";  case 0x3A: return ";";  case 0x3C: return ",";
        case 0x3E: return ".";  case 0x3F: return "/";  case 0x2B: return "=";
        case 0x5F: return "-";  case 0x7B: return "[";  case 0x7D: return "]";
        case 0x7C: return "\\"; case 0x7E: return "`";  case 0x22: return "'";
    }
    // 小键盘 (Qt::KeypadModifier 偏移)
    if (key >= 0x01000060 && key <= 0x01000069) return "Num" + QString::number(key - 0x01000060);
    // F1-F24
    if (key >= Qt::Key_F1 && key <= Qt::Key_F24) return "F" + QString::number(key - Qt::Key_F1 + 1);
    // 特殊键 (存 Qt 键名, QKeySequence 认; "←"/"S-Tab" 解析失败会静默回退 2026-08-23)
    if (key == Qt::Key_Space)       return "Space";
    if (key == Qt::Key_Escape)      return "Esc";
    if (key == Qt::Key_Tab)         return "Tab";
    if (key == Qt::Key_Backtab)     return "Backtab";
    if (key == Qt::Key_Backspace)   return "Back";
    if (key == Qt::Key_Return || key == Qt::Key_Enter) return "Enter";
    if (key == Qt::Key_Insert)      return "Ins";
    if (key == Qt::Key_Delete)      return "Del";
    if (key == Qt::Key_Home)        return "Home";
    if (key == Qt::Key_End)         return "End";
    if (key == Qt::Key_PageUp)      return "PgUp";
    if (key == Qt::Key_PageDown)    return "PgDn";
    // 方向键 (存 Qt 键名, 显示映射回箭头见 nameToDisplay)
    if (key == Qt::Key_Left)        return "Left";
    if (key == Qt::Key_Right)       return "Right";
    if (key == Qt::Key_Up)          return "Up";
    if (key == Qt::Key_Down)        return "Down";
    // 修饰键
    if (key == Qt::Key_Shift)       return "Shift";
    if (key == Qt::Key_Control)     return "Ctrl";
    if (key == Qt::Key_Alt)         return "Alt";
    if (key == Qt::Key_Meta)        return "Win";
    // 符号键 (单字符 QKeySequence 解析成 ASCII → seqVk 映射 OEM VK)
    if (key == 0x2D) return "-";
    if (key == 0x3D) return "=";
    if (key == 0x5B) return "[";
    if (key == 0x5D) return "]";
    if (key == 0x5C) return "\\";
    if (key == 0x3B) return ";";
    if (key == 0x27) return "'";
    if (key == 0x2C) return ",";
    if (key == 0x2E) return ".";
    if (key == 0x2F) return "/";
    if (key == 0x60) return "`";
    // 小键盘符号
    if (key == 0x0100006A) return "Num*";
    if (key == 0x0100006B) return "Num+";
    if (key == 0x0100006C) return "Num,";
    if (key == 0x0100006D) return "Num-";
    if (key == 0x0100006E) return "Num.";
    if (key == 0x0100006F) return "Num/";
    // 其他可打印字符
    if (key >= 0x20 && key <= 0x7E) return QString(QChar(key));
    // 未知键
    return "Key" + QString::number(key);
}

/**
 * ThemeTokens - 应用级设计令牌
 *
 * 统一管理品牌色、功能色、字号、间距等设计变量
 * 所有组件应从此文件导入颜色，避免硬编码
 */

// ============================================================================
// 品牌色
// ============================================================================
export const BRAND_PRIMARY = '#7B68EE';       // 品牌主色（中型紫色）— 所有强调色统一使用
export const BRAND_PRIMARY_LIGHT = '#9B8BFF'; // 品牌主色浅色变体
export const BRAND_PRIMARY_DARK = '#5A4BC8';  // 品牌主色深色变体

// ============================================================================
// 功能色
// ============================================================================
export const COLOR_SUCCESS = '#34C759';       // 成功色（绿色）
export const COLOR_WARNING = '#FF9500';       // 警告色（橙色）
export const COLOR_ERROR = '#FF3B30';         // 错误色（红色）
export const COLOR_INFO = '#5AC8FA';          // 信息色（浅蓝）

// ============================================================================
// 中性色
// ============================================================================
export const COLOR_TEXT_PRIMARY = '#1A1A1A';     // 主要文本
export const COLOR_TEXT_SECONDARY = '#666666';   // 次要文本
export const COLOR_TEXT_TERTIARY = '#999999';    // 三级文本
export const COLOR_TEXT_PLACEHOLDER = '#CCCCCC'; // 占位符文本

export const COLOR_BG_PRIMARY = '#FFFFFF';       // 主要背景
export const COLOR_BG_SECONDARY = '#F5F5F5';     // 次要背景
export const COLOR_BG_TERTIARY = '#EEEEEE';      // 三级背景

// ============================================================================
// 深色模式色
// ============================================================================
export const COLOR_DARK_BG_PRIMARY = '#1C1C1E';     // 深色模式主要背景
export const COLOR_DARK_BG_SECONDARY = '#2C2C2E';   // 深色模式次要背景
export const COLOR_DARK_TEXT_PRIMARY = '#FFFFFF';   // 深色模式主要文本
export const COLOR_DARK_TEXT_SECONDARY = '#ABABAB'; // 深色模式次要文本

// ============================================================================
// 导航栏颜色（已废弃，使用 BRAND_PRIMARY 替代）
// ============================================================================
export const ACTIVE_COLOR = BRAND_PRIMARY;      // 选中态颜色 — 兼容旧代码
export const INACTIVE_COLOR = '#999999';        // 未选中态颜色
export const INACTIVE_TEXT_COLOR = '#999999';   // 未选中文本颜色

// ============================================================================
// 字号规范
// ============================================================================
export const FONT_SIZE_H1 = 28;      // 大标题
export const FONT_SIZE_H2 = 24;      // 中标题
export const FONT_SIZE_H3 = 20;      // 小标题
export const FONT_SIZE_BODY = 16;    // 正文
export const FONT_SIZE_CAPTION = 14; // 说明文字
export const FONT_SIZE_SMALL = 12;   // 辅助文字

// ============================================================================
// 间距规范
// ============================================================================
export const SPACING_XS = 4;
export const SPACING_SM = 8;
export const SPACING_MD = 16;
export const SPACING_LG = 24;
export const SPACING_XL = 32;

// ============================================================================
// 圆角规范
// ============================================================================
export const RADIUS_SM = 4;
export const RADIUS_MD = 8;
export const RADIUS_LG = 12;
export const RADIUS_XL = 16;
export const RADIUS_FULL = 9999;

// ============================================================================
// 动画时长规范
// ============================================================================
export const ANIM_INSTANT = 100;    // 即时反馈：按下缩放、点赞弹跳
export const ANIM_FAST = 150;       // 快速过渡：按钮松开、关闭动画
export const ANIM_NORMAL = 250;     // 标准过渡：聚焦/失焦、滑入/滑出
export const ANIM_SLOW = 400;       // 慢速过渡：面板展开、拖拽回弹
export const ANIM_PAGE = 500;       // 页面级动画：页面淡入、呼吸效果
export const ANIM_INTRO = 800;      // 入场动画：首屏淡入

// ============================================================================
// 动画曲线规范
// ============================================================================
export const CURVE_PRESS = Curve.Sharp;              // 按下：快速响应
export const CURVE_RELEASE = Curve.Friction;         // 松开：弹性回弹
export const CURVE_TRANSITION = Curve.FastOutSlowIn; // 通用过渡：减速停止
export const CURVE_EASE = Curve.EaseInOut;           // 平滑过渡：对称缓入缓出

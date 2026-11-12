package com.example.moviepilot_mobile.widget

/**
 * 同一个渲染逻辑下的多尺寸入口：每个 Provider 对应选择器里的一档默认格数，
 * 渲染层再按实际尺寸自适应（横条 / 小卡 / 列表）。
 */
class SubscribeCalendarWidgetSmallProvider : SubscribeCalendarWidgetProvider()

class SubscribeCalendarWidgetTallProvider : SubscribeCalendarWidgetProvider()

class SubscribeCalendarWidgetLargeProvider : SubscribeCalendarWidgetProvider()

class SubscribeCalendarWidgetBarProvider : SubscribeCalendarWidgetProvider()

package com.example.xclean

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class XCleanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.xclean_widget).apply {
                val score = widgetData.getString("score", "-- / 100")
                val streak = widgetData.getString("streak", "0 Tage")
                val battery = widgetData.getString("battery", "--%")
                val time = widgetData.getString("last_brush_time", "Oclean X Elite")

                setTextViewText(R.id.widget_score, score)
                setTextViewText(R.id.widget_streak, streak)
                setTextViewText(R.id.widget_battery, battery)
                setTextViewText(R.id.widget_time, time)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

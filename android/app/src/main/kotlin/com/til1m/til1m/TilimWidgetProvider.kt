package com.til1m.til1m

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

open class TilimWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)

            val layoutId = when {
                minWidth >= 220 && minHeight >= 220 -> R.layout.widget_large
                minWidth >= 180 -> R.layout.widget_medium
                else -> R.layout.widget_small
            }

            val views = buildViews(context, layoutId, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────

    private fun buildViews(
        context: Context,
        layoutId: Int,
        data: SharedPreferences,
    ): RemoteViews {
        val word = data.getString("word", "") ?: ""
        val transcription = data.getString("transcription", "") ?: ""
        val translation = data.getString("translation", "") ?: ""
        val partOfSpeech = data.getString("part_of_speech", "") ?: ""
        val exampleEn = data.getString("example_en", "") ?: ""
        val audioUrl = data.getString("audio_url", "") ?: ""
        val wordId = data.getString("word_id", "") ?: ""
        val widgetState = data.getString("widget_state", "learning") ?: "learning"
        val learnedToday = data.getInt("learned_today", 0)
        val dailyGoal = data.getInt("daily_goal", 5).coerceAtLeast(1)
        val streakDays = data.getInt("streak_days", 0)
        // Localised strings pushed by WidgetService — no hardcoded text here.
        val completedTitle = data.getString("completed_title", "✔") ?: "✔"
        val progressText = data.getString("progress_text", "$learnedToday / $dailyGoal") ?: "$learnedToday / $dailyGoal"
        val streakText = data.getString("streak_text", "🔥 $streakDays") ?: "🔥 $streakDays"
        val labelReview = data.getString("label_review", "Review") ?: "Review"
        val labelReviewBtn = data.getString("label_review_btn", "Review") ?: "Review"
        val labelEmpty = data.getString("label_empty", "Open TIl1m to start learning") ?: "Open TIl1m to start learning"

        val views = RemoteViews(context.packageName, layoutId)

        // ── Empty state ──────────────────────────────────────────────────────
        if (word.isEmpty()) {
            views.setTextViewText(R.id.widget_placeholder, labelEmpty)
            views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
            views.setViewVisibility(R.id.widget_word_area, View.GONE)
            return views
        }

        // ── Content visible ──────────────────────────────────────────────────
        views.setViewVisibility(R.id.widget_placeholder, View.GONE)
        views.setViewVisibility(R.id.widget_word_area, View.VISIBLE)

        views.setTextViewText(R.id.widget_word, word)
        views.setTextViewText(R.id.widget_transcription, transcription)
        views.setTextViewText(R.id.widget_translation, translation)

        // Progress (medium + large share the same IDs)
        if (layoutId != R.layout.widget_small) {
            val progressPct = when {
                widgetState == "completed" -> 100
                dailyGoal > 0 -> ((learnedToday * 100) / dailyGoal).coerceIn(0, 100)
                else -> 0
            }
            views.setProgressBar(R.id.widget_progress_bar, 100, progressPct, false)
            views.setTextViewText(R.id.widget_progress, progressText)
        }

        // Large-only fields
        if (layoutId == R.layout.widget_large) {
            views.setTextViewText(R.id.widget_part_of_speech, partOfSpeech)
            views.setTextViewText(R.id.widget_streak, streakText)
            if (exampleEn.isNotEmpty()) {
                views.setTextViewText(R.id.widget_example, "\"$exampleEn\"")
                views.setViewVisibility(R.id.widget_example, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_example, View.GONE)
            }
        }

        // ── Widget state styling ─────────────────────────────────────────────
        when (widgetState) {
            "completed" -> {
                safeSetVisibility(views, R.id.widget_label, View.GONE)
                safeSetVisibility(views, R.id.widget_review_btn, View.VISIBLE)
                views.setTextViewText(R.id.widget_review_btn, labelReviewBtn)
                views.setTextViewText(R.id.widget_word, completedTitle)
                views.setTextViewText(R.id.widget_translation, streakText)
            }
            "review" -> {
                safeSetVisibility(views, R.id.widget_label, View.VISIBLE)
                views.setTextViewText(R.id.widget_label, labelReview)
                safeSetVisibility(views, R.id.widget_review_btn, View.VISIBLE)
                views.setTextViewText(R.id.widget_review_btn, labelReviewBtn)
                // FIX: use widget_root (not android.R.id.background which doesn't exist)
                views.setInt(R.id.widget_root, "setBackgroundResource",
                    R.drawable.widget_background_review)
            }
            else -> {
                safeSetVisibility(views, R.id.widget_label, View.GONE)
                safeSetVisibility(views, R.id.widget_review_btn, View.GONE)
            }
        }

        // ── Deep links ───────────────────────────────────────────────────────
        val wordIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("til1m://word?id=$wordId"),
        )
        views.setOnClickPendingIntent(R.id.widget_word_area, wordIntent)

        if (audioUrl.isNotEmpty()) {
            val audioIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("til1m://audio?id=$wordId&url=${Uri.encode(audioUrl)}"),
            )
            safeSetClickIntent(views, R.id.widget_audio_btn, audioIntent)
        }

        val reviewIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("til1m://review"),
        )
        safeSetClickIntent(views, R.id.widget_review_btn, reviewIntent)

        return views
    }

    // ── Safe helpers ──────────────────────────────────────────────────────────

    private fun safeSetVisibility(views: RemoteViews, viewId: Int, visibility: Int) {
        try {
            views.setViewVisibility(viewId, visibility)
        } catch (e: Exception) {
            Log.w(TAG, "safeSetVisibility: viewId=$viewId visibility=$visibility — $e")
        }
    }

    private fun safeSetClickIntent(views: RemoteViews, viewId: Int, intent: PendingIntent) {
        try {
            views.setOnClickPendingIntent(viewId, intent)
        } catch (e: Exception) {
            Log.w(TAG, "safeSetClickIntent: viewId=$viewId — $e")
        }
    }

    companion object {
        private const val TAG = "TilimWidget"
    }
}

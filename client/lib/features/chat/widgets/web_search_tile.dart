import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../../core/models/agent_event.dart';

class WebSearchTile extends StatefulWidget {
  final List<WebSearchResult> results;

  const WebSearchTile({
    super.key,
    required this.results,
  });

  @override
  State<WebSearchTile> createState() => _WebSearchTileState();
}

class _WebSearchTileState extends State<WebSearchTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.results.length} hasil web',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accentBlue),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.results.map(
              (r) => WebResultItem(result: r),
            ),
          ],
        ],
      ),
    );
  }
}

class WebResultItem extends StatelessWidget {
  final WebSearchResult result;

  const WebResultItem({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(result.url);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Uri.tryParse(result.url)?.host ?? result.url,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              result.snippet,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (result.relevanceScore > 0) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'relevansi '
                  '${(result.relevanceScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

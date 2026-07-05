import 'package:flutter/material.dart';

import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/snackbars.dart';
import '../domain/booking_models.dart';

/// BS-004 — Оценка маршала после заезда (LOGIC-006).
class MarshalRatingSection extends StatefulWidget {
  const MarshalRatingSection({
    required this.marshalName,
    required this.submitting,
    required this.onSubmit,
    this.onDelete,
    this.rating,
    this.canEdit = false,
    super.key,
  });

  final String marshalName;
  final bool submitting;
  final bool canEdit;
  final MarshalRating? rating;
  final Future<void> Function(int stars, String? comment) onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<MarshalRatingSection> createState() => _MarshalRatingSectionState();
}

class _MarshalRatingSectionState extends State<MarshalRatingSection> {
  int _stars = 0;
  bool _editing = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromRating(widget.rating);
  }

  @override
  void didUpdateWidget(covariant MarshalRatingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating && !_editing) {
      _syncFromRating(widget.rating);
    }
  }

  void _syncFromRating(MarshalRating? rating) {
    _stars = rating?.stars ?? 0;
    _commentController.text = rating?.comment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1) {
      showAppSnack(context, 'Выберите оценку от 1 до 5 звёзд');
      return;
    }
    final comment = _commentController.text.trim();
    await widget.onSubmit(
      _stars,
      comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    setState(() => _editing = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить оценку?'),
        content: const Text('После удаления можно будет поставить новую оценку.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ApexColors.trackRed,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.onDelete?.call();
  }

  void _startEditing() {
    _syncFromRating(widget.rating);
    setState(() => _editing = true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = widget.rating;
    final showForm = rating == null || _editing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Оценка маршала',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.xs),
            Text(
              widget.marshalName,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: ApexSpacing.sm),
            if (showForm) ...[
              _StarRow(
                stars: _stars,
                interactive: !widget.submitting,
                onChanged: (value) => setState(() => _stars = value),
              ),
              const SizedBox(height: ApexSpacing.sm),
              TextField(
                controller: _commentController,
                enabled: !widget.submitting,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: ApexSpacing.sm),
              Wrap(
                spacing: ApexSpacing.sm,
                runSpacing: ApexSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_editing) ...[
                    TextButton(
                      onPressed: widget.submitting
                          ? null
                          : () => setState(() {
                                _editing = false;
                                _syncFromRating(widget.rating);
                              }),
                      child: const Text('Отмена'),
                    ),
                  ],
                  FilledButton(
                    onPressed: widget.submitting ? null : _submit,
                    child: Text(
                      widget.submitting
                          ? 'Сохраняем…'
                          : _editing
                              ? 'Сохранить'
                              : 'Отправить оценку',
                    ),
                  ),
                ],
              ),
            ] else ...[
              _StarRow(stars: rating!.stars, interactive: false),
              if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                const SizedBox(height: ApexSpacing.sm),
                Text(
                  rating.comment!,
                  style: textTheme.bodyMedium,
                ),
              ],
              if (widget.canEdit) ...[
                const SizedBox(height: ApexSpacing.sm),
                Wrap(
                  spacing: ApexSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: widget.submitting ? null : _startEditing,
                      child: const Text('Изменить'),
                    ),
                    if (widget.onDelete != null)
                      TextButton(
                        onPressed: widget.submitting ? null : _confirmDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: ApexColors.trackRed,
                        ),
                        child: const Text('Удалить'),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.stars,
    required this.interactive,
    this.onChanged,
  });

  final int stars;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        final filled = value <= stars;
        return IconButton(
          onPressed: interactive ? () => onChanged?.call(value) : null,
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled ? ApexColors.trackRed : ApexColors.muted,
          ),
        );
      }),
    );
  }
}

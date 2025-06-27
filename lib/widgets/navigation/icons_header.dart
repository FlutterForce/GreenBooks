import 'package:flutter/material.dart';

class IconsHeader extends StatelessWidget {
  final String? title; // keep nullable
  final Widget? titleWidget; // new: allow a widget title
  final List<IconData>? icons;
  final List<VoidCallback>? onIconTap;
  final List<Widget Function(BuildContext, Widget)?>? iconBuilders;

  const IconsHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.icons,
    this.onIconTap,
    this.iconBuilders,
  }) : assert(
         icons == null || onIconTap == null || icons.length == onIconTap.length,
         'Icons and callbacks length must match',
       ),
       assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final hasIcons = icons != null && onIconTap != null && icons!.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title or titleWidget (with truncation if text)
          titleWidget ??
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          if (hasIcons)
            Row(
              children: List.generate(icons!.length, (index) {
                final iconWidget = Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(icons![index], size: 32, color: Colors.black),
                );

                final wrappedIcon =
                    (iconBuilders != null &&
                        iconBuilders!.length > index &&
                        iconBuilders![index] != null)
                    ? iconBuilders![index]!(context, iconWidget)
                    : iconWidget;

                return GestureDetector(
                  onTap: onIconTap![index],
                  behavior: HitTestBehavior.opaque,
                  child: wrappedIcon,
                );
              }),
            ),
        ],
      ),
    );
  }
}

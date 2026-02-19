import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar widget that displays a person's image or initials
///
/// Shows a circular avatar with either:
/// - A cached network image if imageUrl is provided
/// - Initials (first letter of firstName + lastName) as fallback
class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String firstName;
  final String lastName;
  final double size;

  const Avatar({
    super.key,
    this.imageUrl,
    required this.firstName,
    required this.lastName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Show network image if available
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          backgroundImage: imageProvider,
          radius: size / 2,
        ),
        placeholder: (context, url) => _buildInitials(context),
        errorWidget: (context, url, error) => _buildInitials(context),
      );
    }

    // Fallback to initials
    return _buildInitials(context);
  }

  Widget _buildInitials(BuildContext context) {
    final initials = _getInitials();
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  String _getInitials() {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

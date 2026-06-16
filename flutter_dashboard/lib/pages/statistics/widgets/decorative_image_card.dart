import 'package:flutter/material.dart';

class DecorativeImageCard extends StatelessWidget {
  const DecorativeImageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC3qZrYTGvwqHjjylorhmd9z67NjwR9gm0pr-4DbtWNqW4zaFVUhxDJTpE2MiaN53xGi7yfBSpC8SHn3wXN7L3-fu-0ffLn_BXDoVeLp3JKWAgGjWvyqWikr7OUykfdkzAjkTSCJvvpIWPvZJcUj1TYC9Ssx3KN1kVL6HfSTNwUSmk7c8PFDxN6_9sCshzVXeqWhM-C5Nm-lqPKze6UEcnl9ANZzLIqbyLGYl25KAET1p08MArTTmpZAx6dbTPEwZmA7aQyV8K6TTHl',
              fit: BoxFit.cover,
              color: Colors.grey,
              colorBlendMode: BlendMode.saturation,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            const Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text('Making the world cleaner, one watt at a time.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
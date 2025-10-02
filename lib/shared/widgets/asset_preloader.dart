import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssetPreloader extends StatefulWidget {
  final Widget child;
  final List<String> assetPaths;
  final Widget? loadingWidget;

  const AssetPreloader({
    Key? key,
    required this.child,
    required this.assetPaths,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<AssetPreloader> createState() => _AssetPreloaderState();
}

class _AssetPreloaderState extends State<AssetPreloader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    try {
      // Wait for Flutter to be fully initialized
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Preload all assets
      final futures = widget.assetPaths.map((path) => 
        precacheImage(AssetImage(path), context)
      ).toList();
      
      await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? 
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading assets...'),
                  ],
                ),
              ),
            ),
          ),
        );
    }

    if (_errorMessage != null) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading assets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _preloadAssets();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

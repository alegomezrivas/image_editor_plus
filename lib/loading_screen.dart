import 'package:flutter/material.dart';
import 'package:image_editor_plus/data/constants.dart';
import 'package:image_editor_plus/image_editor_plus.dart';

class LoadingScreen {
  final GlobalKey globalKey;

  LoadingScreen(this.globalKey);

  show([String? text]) {
    if (globalKey.currentContext == null) return;

    showDialog<String>(
      context: globalKey.currentContext!,
      builder: (BuildContext context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: WillPopScope(
              onWillPop: () => Future.value(false),
              child: AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      semanticsLabel: 'Linear progress indicator',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      i18n('Processing...'),
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  hide() {
    if (globalKey.currentContext == null) return;

    Navigator.pop(globalKey.currentContext!);
  }
}

@protected
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();

@protected
var loadingScreen = LoadingScreen(scaffoldGlobalKey);

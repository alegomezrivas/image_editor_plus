import 'package:flutter/material.dart';
import 'package:image_editor_plus/data/settings.dart';
import 'package:image_editor_plus/image_editor_plus.dart';

class LoadingScreen {
  final GlobalKey globalKey;

  LoadingScreen(this.globalKey);

  show({Settings config = const Settings()}) {
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
                    CircularProgressIndicator(
                      semanticsLabel: 'Linear progress indicator',
                      color: config.primaryColor,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      i18n('Processing...'),
                      style: config.normalStyle,
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: config.backgroundColor,
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

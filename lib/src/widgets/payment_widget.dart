import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_paybox/src/flutter_paybox.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWidget extends StatefulWidget {
  static _PaymentWidgetState? of(BuildContext context, {bool root = false}) =>
      root
          ? context.findRootAncestorStateOfType<_PaymentWidgetState>()
          : context.findAncestorStateOfType<_PaymentWidgetState>();

  /// Called on any result from payment
  /// with isSuccess
  final Function(bool isSuccess)? onPaymentDone;
  final PaymentWidgetController? controller;

  PaymentWidget({this.controller, this.onPaymentDone});

  @override
  State<PaymentWidget> createState() {
    var state = _PaymentWidgetState();
    controller?.targetState = state;
    return state;
  }
}

class _PaymentWidgetState extends State<PaymentWidget> {
  String blankPage = 'about:blank';

  WebViewController? _webViewController;

  bool isPaymentDone = false;
  String? _pageUrl;
  bool isLoading = true;

  @override
  void initState() {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.controller?.targetContext = context;
    return Stack(children: [
      WebView(
        zoomEnabled: false,
        initialUrl: getUrl(),
        javascriptMode: JavascriptMode.unrestricted,
        //navigationDelegate: onNavigationDelegate,
        onPageFinished: (String url) {
          setState(() {
            isLoading = false;
          });
          if (url.contains('success')) {
            paymentDone(true);
          } else if (url.contains('failure')) {
            paymentDone(false);
          }
        },
        onWebViewCreated: (controller) => _webViewController = controller,
      ),
      isLoading
          ? Center(
              child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Color(0xFFEB573F),
                    strokeWidth: 2.5,
                  )),
            )
          : Container(),
    ]);
  }

  void setUrl(String? url) {
    setState(() {
      _pageUrl = url;
      if (_webViewController != null)
        _webViewController
            ?.loadUrl(url?.isEmpty == true ? blankPage : (url ?? blankPage));
    });
  }

  NavigationDecision onNavigationDelegate(NavigationRequest request) {
    if (request.url.contains('success')) {
      paymentDone(true);
    } else if (request.url.contains('failure')) {
      paymentDone(false);
    }
    return NavigationDecision.navigate;
  }

  String getUrl() {
    if (_pageUrl?.isEmpty == true) return blankPage;
    if (_pageUrl != null && !isPaymentDone) return _pageUrl!;
    return blankPage;
  }

  void paymentDone(bool result) {
    widget.onPaymentDone?.call(result);
    setState(() {
      isPaymentDone = true;
    });
  }
}

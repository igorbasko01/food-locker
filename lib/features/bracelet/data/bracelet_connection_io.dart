import 'dart:io';

import 'package:food_locker/features/bracelet/data/bracelet_connection.dart'
    show BraceletConnection, UnsupportedBraceletConnection;
import 'package:food_locker/features/bracelet/data/flutter_blue_plus_bracelet_connection.dart';

BraceletConnection createBraceletConnection() => Platform.isAndroid
    ? FlutterBluePlusBraceletConnection()
    : const UnsupportedBraceletConnection();

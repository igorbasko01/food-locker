import 'dart:io';

import 'package:food_locker/features/bracelet/data/bracelet_connection.dart'
    show BraceletConnection, UnsupportedBraceletConnection;
import 'package:food_locker/features/bracelet/data/universal_ble_bracelet_connection.dart';

BraceletConnection createBraceletConnection() => Platform.isAndroid
    ? UniversalBleBraceletConnection()
    : const UnsupportedBraceletConnection();

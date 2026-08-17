import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/// Production integration seams. The portfolio build uses the local repository
/// until Firebase options are supplied, so reviewers can run it immediately.
class FirebaseGateway {
  FirebaseGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);
  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts(String ownerId) =>
      firestore
          .collection('users')
          .doc(ownerId)
          .collection('products')
          .snapshots();
}

class NotificationGateway {
  NotificationGateway({FirebaseMessaging? messaging})
    : messaging = messaging ?? FirebaseMessaging.instance;
  final FirebaseMessaging messaging;
  Future<String?> registerDevice() async {
    await messaging.requestPermission();
    return messaging.getToken();
  }
}

class ExchangeRateService {
  ExchangeRateService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  Future<double> usdTo(String currency) async {
    final response = await _client
        .get(
          Uri.parse('https://api.frankfurter.app/latest?from=USD&to=$currency'),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('Rate service unavailable');
    return ((jsonDecode(response.body)
                as Map<String, dynamic>)['rates'][currency]
            as num)
        .toDouble();
  }
}

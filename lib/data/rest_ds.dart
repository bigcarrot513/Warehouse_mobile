import 'dart:async';
import 'dart:convert';

import 'package:warehouse_mobile/model/product.dart';
import 'package:warehouse_mobile/model/user.dart';
import 'package:warehouse_mobile/utils/network_util.dart';
import 'package:warehouse_mobile/utils/shared_pref_util.dart';

import 'package:device_id/device_id.dart';

class RestDatasource {
  NetworkUtil _netUtil = new NetworkUtil();

  static const API_BASE = '/api/v1';
  static const APP_PORT = '2137';
  static const API_ENDPOINT = 'http://192.168.0.171';
  static const BASE_URL = API_ENDPOINT + ":" + APP_PORT + API_BASE;
  static const LOGIN_URL = BASE_URL + "/login";
  static const REGISTER_URL = BASE_URL + "/user";
  static const GOOGLE_LOGIN_URL = BASE_URL + "/auth/google";
  static const PRODUCTS_URL = BASE_URL + "/products";

  static const PRODUCTS_UPDATE_KEY = 'products';

  Future<Map<String, String>> _getHeaders(
      {bool auth, bool withDeviceId}) async {
    Map<String, String> headers = {
      'content-type': 'application/json',
      'accept': 'application/json'
    };

    if (auth) {
      headers['authorization'] = await SharedPreferencesUtil.getToken();
    }

    if (withDeviceId) {
      headers['device_id'] = await DeviceId.getID;
    }

    return headers;
  }

  Future<User> login(String email, String password) async {
    print('RestDatasource | login | perfoming api call...');

    Map<String, String> body = {'email': email, 'password': password};

    var headers = await _getHeaders(auth: false, withDeviceId: false);

    return _netUtil
        .post(LOGIN_URL, body: json.encode(body), headers: headers)
        .then((dynamic res) {
      var resMap = json.decode(res);

      try {
        return new User.fromJson(resMap);
      } catch (e) {
        throw Exception('Malformed response body');
      }
    }).catchError((error) {
      //some error popup
      print('Login error: ' + error.toString());
    });
  }

  Future<User> register(
      String email, String password, String name, num role) async {
    Map<String, String> body = {
      'email': email,
      'password': password,
      'name': name,
      'role': role.toString(),
      'accType': 0.toString()
    };

    var headers = await _getHeaders(auth: false, withDeviceId: false);

    return _netUtil
        .post(REGISTER_URL, body: json.encode(body), headers: headers)
        .then((dynamic res) {
      var resMap = json.decode(res);

      try {
        return new User.fromJson(resMap);
      } catch (e) {
        throw Exception('Malformed response body');
      }
    }).catchError((error) {
      //some error popup
      print('Register error: ' + error.toString());
    });
  }

  Future<User> googleLogin(String accessToken, String idToken) async {
    print('RestDatasource | googleLogin | perfoming api call...');

    Map<String, String> body = {'accessToken': accessToken, 'idToken': idToken};

    var headers = await _getHeaders(auth: false, withDeviceId: false);

    return _netUtil
        .post(GOOGLE_LOGIN_URL, body: json.encode(body), headers: headers)
        .then((dynamic res) {
      var resMap = json.decode(res);

      print(resMap);

      try {
        return new User.fromJson(resMap);
      } catch (e) {
        throw Exception('Malformed response body');
      }
    }).catchError((error) {
      //some error popup
      print('Google login error: ' + error.toString());
    });
  }

  Future<List<Product>> getProducts() async {
    var headers = await _getHeaders(auth: true, withDeviceId: true);

    return _netUtil.get(PRODUCTS_URL, headers).then((dynamic res) {
      Iterable resCollection = json.decode(res);
      return resCollection.map((obj) => Product.fromJson(obj)).toList();
    }).catchError((error) {
      //some error popup
      print('Get products error: ' + error.toString());
    });
  }

  Future<void> updateProducts(List<Product> products) async {
		var headers = await _getHeaders(auth: true, withDeviceId: true);

		List<Map> rawProducts = [];
		products.forEach((product) {
			rawProducts.add(product.toMap());
		});

		var body = {
			PRODUCTS_UPDATE_KEY: rawProducts
		};

		return _netUtil
			.patch(PRODUCTS_URL, body: json.encode(body), headers: headers)
			.then((dynamic res) {

		}).catchError((error) {
			//some error popup
			print('Get products error: ' + error.toString());
		});
	}

  Future<Product> getProduct(String productID) async {
    var headers = await _getHeaders(auth: true, withDeviceId: true);

    var url = PRODUCTS_URL + '/' + productID;

    return _netUtil.get(url, headers).then((dynamic res) {
      var resObj = json.decode(res);

      return Product.fromJson(resObj);
    });
  }

  Future<void> removeProduct(String productID) async {
    var headers = await _getHeaders(auth: true, withDeviceId: true);

    var url = PRODUCTS_URL + '/' + productID;

    return _netUtil.delete(url, headers);
  }

  Future<int> changeProductItems(Product product) async {
    var headers = await _getHeaders(auth: true, withDeviceId: true);

    var quantity = product.localQuantity;

    var url = PRODUCTS_URL + '/' + product.id;

    var body = {Product.QUANTITY_KEY: quantity.toString()};

    return _netUtil
        .patch(url, body: json.encode(body), headers: headers)
        .then((dynamic res) {
      var resObj = json.decode(res);

      return int.parse(resObj[Product.QUANTITY_KEY].toString());
    }).catchError((dynamic err) {
      throw err;
    });
  }

  Future<Product> addProduct(String manufacturerName, String productModelName,
      num price, String currency) async {
    var headers = await _getHeaders(auth: true, withDeviceId: true);

    var body = {
      'manufacturerName': manufacturerName,
      'productModelName': productModelName,
      'price': price,
      'currency': currency
    };

    return _netUtil
        .post(PRODUCTS_URL, body: json.encode(body), headers: headers)
        .then((dynamic res) {
      var productObj = json.decode(res);

      return Product.fromJson(productObj);
    }).catchError((dynamic err) {
      return err;
    });
  }
}

part of 'net_module.dart';

class HttpUtil {
  static HttpUtil? _instance;

  static late String _initBaseUrl;

  static Dio? _dio;

  static final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  late HttpController _controller;

  ///第一次初始化baseUrl不能为空
  ///之后调用构造函数获取单例时，传入baseUrl会改变baseURL，要重置为初始化url调用[resetInitUrl]
  ///如果请求时临时改变url在调用请求时，传入tempChangeUrl
  factory HttpUtil({
    String? baseUrl,
    int? cTimeout,
    int? rTimeout,
    Map<String, dynamic>? headers,
    String? cType,
    ResponseType? rType,
    Interceptor? responseOuterInterceptor,
    bool isLog = true,
    List<Interceptor>? interceptors,
  }) {
    if (_instance == null && baseUrl == null) {
      throw Exception('初始化HttpUtil未配置baseUrl');
    }

    if (_instance == null && baseUrl != null) {
      _initBaseUrl = baseUrl;
      _instance = HttpUtil._internal(
        baseUrl,
        cTimeout,
        rTimeout,
        headers,
        cType,
        rType,
        responseOuterInterceptor,
        isLog,
        interceptors,
      );
    }

    if (baseUrl != null) return _baseUrl(baseUrl);
    return _instance!;
  }

  //用于指定特定域名
  static HttpUtil _baseUrl(String baseUrl) {
    if (_dio != null) {
      _dio!.options.baseUrl = baseUrl;
    }
    return _instance!;
  }

  HttpUtil._internal(
    String baseUrl,
    int? cTimeout,
    int? rTimeout,
    Map<String, dynamic>? headers,
    String? cType,
    ResponseType? rType,
    Interceptor? responseOuterInterceptor,
    bool isLog,
    List<Interceptor>? interceptors,
  ) {
    _controller = HttpController();
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: cTimeout ?? 30000),
      receiveTimeout: Duration(milliseconds: cTimeout ?? 30000),
      headers: headers,
      contentType: cType,
      responseType: rType,
    );

    _dio = Dio(options);

    if (isLog) {
      _dio!.interceptors.add(HttpErrorLogInterceptor());
      _dio!.interceptors.add(HttpResponseLogInterceptor());
    }

    if (responseOuterInterceptor != null) {
      _dio!.interceptors.add(responseOuterInterceptor);
    }

    _dio!.interceptors.add(ConnectionStatusInterceptor(_controller));

    _dio!.interceptors.add(ChangeBaseUrlInterceptor());

    if (interceptors != null && interceptors.isNotEmpty) {
      _dio!.interceptors.addAll(interceptors);
    }

    if (isLog) {
      _dio!.interceptors.add(HttpRequestLogInterceptor());
    }
  }

  Dio? get dio => _dio;

  /// 重置默认url,默认url为初始化单例时传入BaseUrl
  void resetInitUrl() {
    assert(_instance != null, 'HttpUtil实例为null');
    assert(_dio != null, 'Dio实例为null');
    if (_instance == null || _dio == null) return;
    _dio!.options.baseUrl = _initBaseUrl;
  }

  HttpController httpController() => _controller;

  void cancelRequest(String tokenName) {
    tokenName = tokenName.split('(')[0];
    _cancelTokens[tokenName]?.cancel("cancelled");
  }

  void removeCancelToken(BuildContext context) {
    _cancelTokens.removeWhere((key, token) {
      return token == _getCancelToken(context);
    });
  }

  CancelToken? _getCancelToken(BuildContext context) {
    CancelToken? cancelToken;
    String cancelTokenKey = context.toString().split('(')[0];
    if (!_cancelTokens.containsKey(cancelTokenKey)) {
      cancelToken = CancelToken();
      _cancelTokens[cancelTokenKey] = cancelToken;
    } else {
      cancelToken = _cancelTokens[cancelTokenKey];
    }
    return cancelToken;
  }

  Future<T?> _request<T>(
    String method,
    BuildContext context,
    Options options,
    String path, {
    dynamic query,
    dynamic data,
    String? tempChangeUrl,
    required bool isLogRequest,
    required bool isLogResponse,
    required bool isRefresh,
    required bool isCache,
    String? reqContentType,
  }) async {
    Options requestOptions = options;
    requestOptions = requestOptions.copyWith(
      method: method,
      extra: {
        "context": context,
        if (!tempChangeUrl.blank) "OTHER_BASE_URL": tempChangeUrl,
        extraLogRequest: isLogRequest,
        extraLogResponse: isLogResponse,
        extraRefresh: isRefresh,
        extraCache: isCache,
        extraReqContentType: reqContentType,
      },
    );
    var response = await _dio!.request<T>(
      path,
      queryParameters: query,
      data: data,
      options: requestOptions,
    );
    return response.data;
  }

  /// restful get 操作
  /// 如果请求时临时改变url在调用时，传入tempChangeUrl
  Future<T?> get<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'GET',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }

  /// restful post 操作
  /// 如果请求时临时改变url在调用时，传入tempChangeUrl
  Future<T?> post<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'POST',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }

  /// restful put 操作
  Future<T?> put<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'PUT',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }

  /// restful delete 操作
  Future<T?> delete<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'DELETE',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }

  /// restful patch 操作
  Future<T?> patch<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'PATCH',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }

  /// restful head 操作
  Future<T?> head<T>(
    BuildContext context,
    String path, {
    dynamic query,
    dynamic params,
    String? tempChangeUrl,
    Options? options,
    bool isLogRequest = false,
    bool isLogResponse = false,
    bool isRefresh = false,
    bool isCache = false,
    String? reqContentType,
  }) async {
    Options requestOptions = options ?? Options();
    return _request<T>(
      'HEAD',
      context,
      requestOptions,
      path,
      tempChangeUrl: tempChangeUrl,
      query: query,
      data: params,
      isLogRequest: isLogRequest,
      isLogResponse: isLogResponse,
      isCache: isCache,
      isRefresh: isRefresh,
      reqContentType: reqContentType,
    );
  }
}

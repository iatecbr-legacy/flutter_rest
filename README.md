# rest

A rest client base to make API requests.

Example

```dart
class LoginApi extends Rest {
  LoginApi() {
    this.addInterceptor(PrintLogInterceptor());
  }

  @override
  String get restUrl => BASE_AUTH_URL_API;

  Future<RestResult<User>> login(String user, String password) =>
      postModel("/login", { "user": user, "password": password }, User.fromJson);
}

class User {
    int id;
    String userName;
    String token;

    static User fromJson(Map<String, dynamic> json) {
        ///... parse json to User
    }

    Map<String, dynamic> toJson() {
        //... properties to map
    }
}
```
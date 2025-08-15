import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lang_ai/services/google_login_service.dart';
import 'package:http/http.dart' as http;

class GithubAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Github 로그인 시도
  // '다른 제공자 계정 충돌(google.com)'이면 Google 로그인 후 GitHub 계정을 자동 링크하여 같은 UID로 통합
  Future<UserCredential?> signInWithGithub(BuildContext context) async {
    try {
      final provider = GithubAuthProvider();
      provider.addScope('read:user');
      provider.addScope('user:email');

      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);

      await _ensureDisplayNameAndPhotoFromGithub(cred);
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'web-context-cancelled') {
        debugPrint('GitHub 로그인 취소: ${e.code}');
        return null;
      }

      // 같은 이메일로 이미 다른 제공자에 가입된 경우 (ex.google)
      if (e.code == 'account-exists-with-different-credential') {
        final proceed = await _askUserToLoginWithExistingMethod(context);
        if (!proceed) return null;

        final googleCred = await GoogleAuthService().signInWithGoogle(context);
        if (googleCred == null) return null;

        final current = _auth.currentUser;
        if (current == null) {
          throw FirebaseAuthException(
              code: 'no-current-user', message: '먼저 로그인해주세요.');
        }

        // 같은 UID로 GitHub을 링크함
        final githubProvider = GithubAuthProvider();
        githubProvider.addScope('read:user');
        githubProvider.addScope('user:email');
        final linked = kIsWeb
            ? await current.linkWithPopup(githubProvider)
            : await current.linkWithProvider(githubProvider);

        return linked;
      }

      rethrow;
    } catch (e) {
      debugPrint('Github 로그인 실패: $e');
      return null;
    }
  }

  // 중립적 메시지: 이메일 존재 여부/제공자 노출 금지 (보안 권장)
  Future<bool> _askUserToLoginWithExistingMethod(BuildContext context) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('계정 확인 필요'),
            content: const Text(
              '해당 계정은 이미 다른 방식으로 사용 중일 수 있어요.\n'
              '먼저 기존에 사용하던 방법으로 로그인한 뒤, GitHub를 연결해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('계속'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _ensureDisplayNameAndPhotoFromGithub(UserCredential cred) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final alreadyHasName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty);
    final alreadyHasPhoto =
        (user.photoURL != null && user.photoURL!.trim().isNotEmpty);
    if (alreadyHasName && alreadyHasPhoto) return;

    // 1) 먼저 AdditionalUserInfo.profile에서 시도 (로그인 응답에 실려옴)
    String? name;
    String? login;
    String? avatarUrl;

    final profile = cred.additionalUserInfo?.profile;
    if (profile != null) {
      name = (profile['name'] as String?)?.trim();
      login = (profile['login'] as String?)?.trim(); // 깃허브 핸들
      avatarUrl = (profile['avatar_url'] as String?)?.trim();
    }

    // 2) 그래도 비어 있으면, 액세스 토큰으로 /user 호출해서 보강
    //    (name은 null일 수 있지만 login은 항상 존재. avatar_url도 제공)
    if ((name == null ||
        name.isEmpty ||
        avatarUrl == null ||
        avatarUrl.isEmpty)) {
      final token = cred.credential?.accessToken;
      if (token != null) {
        final resp = await http.get(
          Uri.parse('https://api.github.com/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github+json',
          },
        );
        if (resp.statusCode == 200) {
          final m = json.decode(resp.body) as Map<String, dynamic>;
          name ??= (m['name'] as String?)?.trim();
          login ??= (m['login'] as String?)?.trim();
          avatarUrl ??= (m['avatar_url'] as String?)?.trim();
        }
      }
    }

    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (login != null && login.isNotEmpty ? login : 'GitHub 사용자');

    // 3) Firebase 사용자 프로필 갱신
    if (!alreadyHasName) {
      await user.updateDisplayName(displayName);
    }
    if (!alreadyHasPhoto && avatarUrl != null && avatarUrl.isNotEmpty) {
      await user.updatePhotoURL(avatarUrl);
    }
  }
}

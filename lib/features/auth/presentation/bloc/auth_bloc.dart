import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se7ety/core/enums/user_type_enum.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<RegisterEvent>(register);
    on<LoginEvent>(login);
    on<UpdateDoctorDataEvent>(updateDoctorData);
  }

  // Login
  Future<void> login(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginLoadingState());

    try {
      log('LOGIN: Starting login for "${event.email}"');

      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      final user = credential.user;

      if (user == null) {
        log('LOGIN ERROR: Firebase returned null user');
        emit(AuthErrorState(
            message: 'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى'));
        return;
      }

      log('LOGIN SUCCESS: UID = ${user.uid}');
      log('LOGIN SUCCESS: Email = ${user.email}');
      log('LOGIN SUCCESS: PhotoURL = ${user.photoURL}');

      emit(
        LoginSuccessState(
          userType: user.photoURL ?? '',
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      log('FIREBASE AUTH ERROR CODE: ${e.code}');
      log('FIREBASE AUTH ERROR MESSAGE: ${e.message}');
      log('FIREBASE AUTH STACKTRACE: $stackTrace');

      switch (e.code) {
        case 'user-not-found':
          emit(AuthErrorState(message: 'المستخدم غير موجود'));
          break;

        case 'wrong-password':
          emit(AuthErrorState(message: 'كلمة المرور غير صحيحة'));
          break;

        case 'invalid-credential':
          emit(
            AuthErrorState(
              message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
            ),
          );
          break;

        case 'invalid-email':
          emit(
            AuthErrorState(
              message: 'البريد الإلكتروني غير صحيح',
            ),
          );
          break;

        case 'user-disabled':
          emit(
            AuthErrorState(
              message: 'هذا الحساب معطّل',
            ),
          );
          break;

        case 'too-many-requests':
          emit(
            AuthErrorState(
              message: 'محاولات كثيرة، حاول مرة أخرى لاحقًا',
            ),
          );
          break;

        case 'network-request-failed':
          emit(
            AuthErrorState(
              message: 'تحقق من اتصال الإنترنت وحاول مرة أخرى',
            ),
          );
          break;

        case 'operation-not-allowed':
          emit(
            AuthErrorState(
              message: 'تسجيل الدخول بالبريد الإلكتروني غير مفعّل في Firebase',
            ),
          );
          break;

        case 'channel-error':
          emit(
            AuthErrorState(
              message: 'خطأ في الاتصال بـ Firebase، حاول مرة أخرى',
            ),
          );
          break;

        default:
          emit(
            AuthErrorState(
              message: 'خطأ في تسجيل الدخول: ${e.code}',
            ),
          );
      }
    } on FirebaseException catch (e, stackTrace) {
      log('LOGIN FIREBASE ERROR: ${e.code} - ${e.message}');
      log('LOGIN FIREBASE STACKTRACE: $stackTrace');
      emit(
        AuthErrorState(
          message: 'خطأ Firebase: ${e.message}',
        ),
      );
    } catch (e, stackTrace) {
      log('LOGIN GENERAL ERROR TYPE: ${e.runtimeType}');
      log('LOGIN GENERAL ERROR: $e');
      log('LOGIN GENERAL STACKTRACE: $stackTrace');

      emit(
        AuthErrorState(
          message: 'خطأ غير متوقع (${e.runtimeType}): $e',
        ),
      );
    }
  }

  // Register
  Future<void> register(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    log('REGISTER: Starting registration for ${event.email}');

    emit(RegisterLoadingState());

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      User? user = credential.user;

      if (user == null) {
        throw Exception('Firebase returned a null user');
      }

      await user.updateDisplayName(event.name);

      // Use photoURL to store the user role.
      await user.updatePhotoURL(event.userType.toString());

      log('REGISTER: PhotoURL = ${user.photoURL}');

      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      log('REGISTER: DisplayName = ${user?.displayName}');
      log('REGISTER: UID = ${user?.uid}');

      if (user == null) {
        throw Exception('User not found after reload');
      }

      // Store user data in Firestore.
      if (event.userType == UserType.doctor) {
        await FirebaseFirestore.instance
            .collection('doctor')
            .doc(user.uid)
            .set({
          'name': event.name,
          'image': '',
          'specialization': '',
          'rating': 3,
          'email': event.email,
          'phone1': '',
          'phone2': '',
          'bio': '',
          'openHour': '',
          'closeHour': '',
          'address': '',
          'uid': user.uid,
        });

        log('REGISTER: Doctor data saved successfully');
      } else {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .set({
          'name': event.name,
          'image': '',
          'age': '',
          'email': event.email,
          'phone': '',
          'bio': '',
          'city': '',
          'uid': user.uid,
        });

        log('REGISTER: Patient data saved successfully');
      }

      emit(RegisterSuccessState());

      log('REGISTER SUCCESS');
    } on FirebaseAuthException catch (e, stackTrace) {
      log('REGISTER AUTH ERROR CODE: ${e.code}');
      log('REGISTER AUTH ERROR MESSAGE: ${e.message}');
      log('REGISTER AUTH STACKTRACE: $stackTrace');

      switch (e.code) {
        case 'weak-password':
          emit(
            AuthErrorState(
              message: 'كلمة المرور ضعيفة',
            ),
          );
          break;

        case 'email-already-in-use':
          emit(
            AuthErrorState(
              message: 'البريد الإلكتروني مستخدم من قبل',
            ),
          );
          break;

        case 'invalid-email':
          emit(
            AuthErrorState(
              message: 'البريد الإلكتروني غير صحيح',
            ),
          );
          break;

        case 'operation-not-allowed':
          emit(
            AuthErrorState(
              message: 'إنشاء الحساب بالبريد الإلكتروني غير مفعّل في Firebase',
            ),
          );
          break;

        case 'network-request-failed':
          emit(
            AuthErrorState(
              message: 'تحقق من اتصال الإنترنت وحاول مرة أخرى',
            ),
          );
          break;

        default:
          emit(
            AuthErrorState(
              message: 'خطأ في إنشاء الحساب: ${e.code}',
            ),
          );
      }
    } on FirebaseException catch (e, stackTrace) {
      log('REGISTER FIREBASE ERROR CODE: ${e.code}');
      log('REGISTER FIREBASE ERROR MESSAGE: ${e.message}');
      log('REGISTER FIREBASE STACKTRACE: $stackTrace');

      emit(
        AuthErrorState(
          message: 'تم إنشاء الحساب، لكن حدث خطأ أثناء حفظ البيانات',
        ),
      );
    } catch (e, stackTrace) {
      log('REGISTER GENERAL ERROR TYPE: ${e.runtimeType}');
      log('REGISTER GENERAL ERROR: $e');
      log('REGISTER GENERAL STACKTRACE: $stackTrace');

      emit(
        AuthErrorState(
          message: 'خطأ غير متوقع (${e.runtimeType}): $e',
        ),
      );
    }
  }

  // Update Doctor Data
  Future<void> updateDoctorData(
    UpdateDoctorDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(DoctorRegistrationLoadingState());

    try {
      log('UPDATE DOCTOR: Starting update');
      log('UPDATE DOCTOR DATA: ${event.doctorModel.toJson()}');

      await FirebaseFirestore.instance
          .collection('doctor')
          .doc(event.doctorModel.uid)
          .update(event.doctorModel.toJson());

      log('UPDATE DOCTOR: Success');

      emit(DoctorRegistrationSuccessState());
    } on FirebaseException catch (e, stackTrace) {
      log('UPDATE DOCTOR FIREBASE ERROR CODE: ${e.code}');
      log('UPDATE DOCTOR FIREBASE ERROR MESSAGE: ${e.message}');
      log('UPDATE DOCTOR STACKTRACE: $stackTrace');

      emit(
        AuthErrorState(
          message: 'حدث خطأ أثناء تحديث بيانات الطبيب',
        ),
      );
    } catch (e, stackTrace) {
      log('UPDATE DOCTOR GENERAL ERROR: $e');
      log('UPDATE DOCTOR STACKTRACE: $stackTrace');

      emit(
        AuthErrorState(
          message: 'حدث خطأ ما، يرجى المحاولة مرة أخرى',
        ),
      );
    }
  }
}



import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:upi_india/upi_india.dart';

import '../model/dlv_model.dart';
import '../view/delivery_boy/dlv_home.dart';


class BackendServices {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  DlvDtl? _userModel;
  DlvDtl get userModel => _userModel!;

  Future<void> saveUser( String username, String userEmail,String collectionName) async {
   final userDoc=  firebaseFirestore
        .collection(collectionName)
        .doc();
    _userModel = DlvDtl(userId: userDoc.id, userEmail: userEmail, userName: username);
    await userDoc
        .set(_userModel!.toMap());
  }
  Future<void>signUp(String userName,String userPassword,String userEmail,context,String collectionName, )async{
    try{
      UserCredential userCredential =await firebaseAuth.createUserWithEmailAndPassword(email: userEmail, password: userPassword);
      final user =firebaseAuth.currentUser;
      user!.sendEmailVerification();
      await saveUser(userName, userEmail,collectionName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success")));


    }catch(e){
      print(e);
    }

  }
  Future<void>lognin (String userEmail,String userPass,context)async{
    try{
      await firebaseAuth.signInWithEmailAndPassword(email: userEmail, password: userPass);
      final user =firebaseAuth.currentUser;
      final emailVerified = user!.emailVerified;
      if(emailVerified==false){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please verified")));

      }else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>DlvHome()));
      }

    }
    on FirebaseAuthException catch(e){
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.toString())));
    }
    catch(e){
      print(e);

    }
  }
  Future<void> forgotPassword(String userEmail,context)async{
    try{
      await firebaseAuth.sendPasswordResetEmail(email: userEmail);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email send check your inbox")));
    }
    on FirebaseAuthException catch(e){
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.toString())));
    }
    catch(e){
      print(e);

    }
  }
  String? _uid;
  String get uid => _uid!;
  Future<void>fetchUserData()async{
    try{
      await firebaseFirestore.collection('users').doc(firebaseAuth.currentUser!.uid).get().then((DocumentSnapshot snapshot) {
        _userModel = DlvDtl(userId: snapshot['userId'], userName: snapshot['userName'], userEmail: snapshot['userEmail']);
        _uid =userModel.userId;
      });

    }
    catch(e){
      print(e);

    }
  }
  //////////////////////////////////////////////////////////////////////////
  UpiIndia _upiIndia = UpiIndia();
  UpiApp app = UpiApp.googlePay;
  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    return _upiIndia.startTransaction(
      app: app,
      receiverUpiId: "9078600498@ybl",
      receiverName: 'Md Azharuddin',
      transactionRefId: 'TestingUpiIndiaPlugin',
      transactionNote: 'Not actual. Just an example.',
      amount: 1.00,
    );
  }



  Future<void> editProfile(String userName, String password, String userEmail, File image, String address, String mobileNumber, context) async {
  try {
  String imageUrl = await uploadImage(image); // Upload image to Firebase Storage
  await firebaseFirestore
      .collection("users")
      .doc(firebaseAuth.currentUser!.uid)
      .update({
  "userName": userName,
  "Password": password,
  "Email": userEmail,
  "Address": address,
  "MobileNumber": mobileNumber, // Save image URL to Firestore
  });
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Profile updated successfully")));
  } catch (e) {
  print('Error editing profile: $e');
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Failed to update profile")));
  }
  }
  Future<String> uploadImage( image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
      FirebaseStorage.instance.ref().child('images/$fileName');
      UploadTask uploadTask = reference.putFile(image );
      TaskSnapshot storageTaskSnapshot = await uploadTask;
      String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      print(downloadUrl);
      await firebaseFirestore
          .collection("users")
          .doc(firebaseAuth.currentUser!.uid)
          .update({

        'imageUrl': downloadUrl, // Save image URL to Firestore
      });
      return downloadUrl;
    } catch (e) {
      print('error uploading image:$e');
      return '';
    }
  }
}



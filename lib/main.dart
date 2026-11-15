import 'dart:ui';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey, accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken());
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Travel Expense',
    themeMode: ThemeMode.dark,
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff070a10),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6ea8ff), brightness: Brightness.dark),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white.withValues(alpha: .06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
      }
      return snap.data == null ? const LoginPage() : HomeShell(user: snap.data!);
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool busy = false; String? error;
  Future<void> login() async {
    setState(() { busy = true; error = null; });
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: auth.idToken));
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) setState(() => error = e.description ?? 'Google sign-in failed');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? e.code);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Stack(children: [
    const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(-.8,-.8), radius: 1.5, colors: [Color(0xff1b3157), Color(0xff070a10), Color(0xff070a10)])))),
    SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Container(width: 76, height: 76, alignment: Alignment.center, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xff78afff), Color(0xff9b7bff)]), borderRadius: BorderRadius.circular(24)), child: const Icon(CupertinoIcons.doc_text_viewfinder, size: 38)),
      const SizedBox(height: 24),
      const Text('Every bill.\nOne trip at a time.', style: TextStyle(fontSize: 40, height: 1.05, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      const Text('Capture receipts during travel and keep every expense inside the right trip.', style: TextStyle(fontSize: 17, color: Colors.white70, height: 1.45)),
      const Spacer(),
      if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffff8a8a)))),
      FilledButton.icon(onPressed: busy ? null : login, icon: busy ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(CupertinoIcons.person_crop_circle_badge_checkmark), label: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(busy ? 'Signing in...' : 'Continue with Google'))),
      const SizedBox(height: 14), const Text('Your expenses stay private inside your account.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
    ])))
  ]));
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.user, super.key}); final User user;
  @override State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    Widget page = switch(index) { 0 => const TripsPage(), 1 => const BillsPage(), 2 => const AddBillPage(), _ => ProfilePage(user: widget.user) };
    return Scaffold(extendBody:true, body: KeyedSubtree(key: ValueKey(index), child: page), bottomNavigationBar: SafeArea(top:false, child: Padding(padding: const EdgeInsets.fromLTRB(14,0,14,10), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX:16,sigmaY:16), child: NavigationBar(backgroundColor: const Color(0xcc121722), selectedIndex:index, onDestinationSelected:(v)=>setState(()=>index=v), destinations: const [
      NavigationDestination(icon:Icon(CupertinoIcons.map),selectedIcon:Icon(CupertinoIcons.map_fill),label:'Trips'),
      NavigationDestination(icon:Icon(CupertinoIcons.doc_text),selectedIcon:Icon(CupertinoIcons.doc_text_fill),label:'Bills'),
      NavigationDestination(icon:Icon(CupertinoIcons.camera),selectedIcon:Icon(CupertinoIcons.camera_fill),label:'Add'),
      NavigationDestination(icon:Icon(CupertinoIcons.person),selectedIcon:Icon(CupertinoIcons.person_fill),label:'Profile'),
    ]))))));
  }
}

class PageList extends StatelessWidget {
  const PageList({required this.title, required this.children, this.action, super.key});
  final String title; final List<Widget> children; final Widget? action;
  @override Widget build(BuildContext context) => CustomScrollView(slivers:[
    SliverAppBar.large(pinned:true,title:Text(title),backgroundColor:const Color(0xeb070a10),actions:action == null ? null : [action!]),
    SliverPadding(padding:const EdgeInsets.fromLTRB(16,8,16,110),sliver:SliverList.list(children:children))
  ]);
}
class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding=const EdgeInsets.all(18), super.key}); final Widget child; final EdgeInsets padding;
  @override Widget build(BuildContext context) => Container(padding:padding,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.06),borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white.withValues(alpha:.09))),child:child);
}

class Trip { const Trip(this.id,this.name,this.place,this.dates,this.total,this.count,this.active); final String id,name,place,dates,total; final int count; final bool active;
  factory Trip.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) { final d=doc.data()??{}; return Trip(doc.id,(d['name']??'Untitled trip').toString(),(d['destination']??'').toString(),(d['dateLabel']??'Dates not set').toString(),(d['totalLabel']??'No expenses').toString(),(d['billCount'] as num?)?.toInt()??0,(d['status']??'active')=='active'); }
}
class Bill {
  const Bill(this.id,this.tripId,this.merchant,this.category,this.amountMinor,this.currency,this.dateLabel,this.notes,this.receiptPath);
  final String id,tripId,merchant,category,currency,dateLabel,notes,receiptPath;
  final int amountMinor;
  String get amountLabel => '$currency ${(amountMinor/100).toStringAsFixed(2)}';
  factory Bill.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc,String tripId){
    final d=doc.data()??{};
    return Bill(doc.id,tripId,(d['merchant']??'Untitled bill').toString(),(d['category']??'Other').toString(),(d['amountMinor'] as num?)?.toInt()??0,(d['currency']??'INR').toString(),(d['dateLabel']??'Date not set').toString(),(d['notes']??'').toString(),(d['receiptPath']??'').toString());
  }
}

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});
  @override Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser!.uid;
    final query=FirebaseFirestore.instance.collection('users').doc(uid).collection('trips').orderBy('createdAt',descending:true);
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:query.snapshots(),
      builder:(context,snap){
        final action=IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NewTripPage())),icon:const Icon(CupertinoIcons.add));
        if(snap.hasError){return PageList(title:'Trips',action:action,children:[GlassCard(child:Text('Unable to load trips: ${snap.error}',style:const TextStyle(color:Color(0xffff8a8a))))]);}
        if(!snap.hasData){return PageList(title:'Trips',action:action,children:const [Center(child:Padding(padding:EdgeInsets.all(40),child:CupertinoActivityIndicator()))]);}
        final items=snap.data!.docs.map(Trip.fromDoc).toList();
        return PageList(title:'Trips',action:action,children:[
          GlassCard(child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ready for a new journey?',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Create a trip, then keep every bill together.',style:TextStyle(color:Colors.white60))])),const SizedBox(width:12),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NewTripPage())),child:const Text('New trip'))])),
          const SizedBox(height:24),
          if(items.isEmpty) const GlassCard(child:Column(children:[Icon(CupertinoIcons.map,size:44,color:Color(0xff90baff)),SizedBox(height:12),Text('No trips yet',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Create the first trip to begin saving bills.',style:TextStyle(color:Colors.white60))])) else ...items.map((t)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TripCard(trip:t))),
        ]);
      },
    );
  }
}
class TripCard extends StatelessWidget {
  const TripCard({required this.trip,super.key}); final Trip trip;
  @override Widget build(BuildContext context) => InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TripDetailPage(trip:trip))),child:GlassCard(child:Column(children:[
    Row(children:[Container(width:48,height:48,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xff4f8cff),Color(0xff8b5cf6)]),borderRadius:BorderRadius.circular(16)),child:const Icon(CupertinoIcons.airplane)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(trip.name,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),Text(trip.place,style:const TextStyle(color:Colors.white60))])),const Icon(CupertinoIcons.chevron_right,size:16)]),
    const SizedBox(height:18),Row(children:[Text(trip.dates,style:const TextStyle(color:Colors.white60)),const Spacer(),Text(trip.total,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]),const SizedBox(height:12),Row(children:[const Icon(CupertinoIcons.doc_text,size:17,color:Color(0xff90baff)),const SizedBox(width:8),Text('${trip.count} bills'),const Spacer(),Text(trip.active?'Active':'Completed',style:TextStyle(color:trip.active?const Color(0xff72e7b4):Colors.white60,fontWeight:FontWeight.w700))])
  ])));
}
class TripDetailPage extends StatelessWidget {
  const TripDetailPage({required this.trip,super.key}); final Trip trip;
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser!.uid;
    final stream=FirebaseFirestore.instance.collection('users').doc(uid).collection('trips').doc(trip.id).collection('bills').orderBy('createdAt',descending:true).snapshots();
    return Scaffold(
      appBar:AppBar(title:Text(trip.name)),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AddBillPage(trip:trip))),icon:const Icon(CupertinoIcons.add),label:const Text('Add bill')),
      body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:stream,builder:(context,snap){
        if(snap.hasError){return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Unable to load bills: ${snap.error}',style:const TextStyle(color:Color(0xffff8a8a)))));}
        if(!snap.hasData){return const Center(child:CupertinoActivityIndicator());}
        final items=snap.data!.docs.map((d)=>Bill.fromDoc(d,trip.id)).toList();
        final total=items.fold<int>(0,(sum,b)=>sum+b.amountMinor);
        final currency=items.isEmpty?'':items.first.currency;
        return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
          GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(trip.place.isEmpty?'No destination':trip.place,style:const TextStyle(color:Colors.white60)),const SizedBox(height:6),Text(items.isEmpty?'No expenses':'$currency ${(total/100).toStringAsFixed(2)}',style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900)),Text('${items.length} bills',style:const TextStyle(color:Colors.white60))])),
          const SizedBox(height:22),const Text('Bills',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:12),
          if(items.isEmpty) const GlassCard(child:Column(children:[Icon(CupertinoIcons.doc_text,size:44,color:Color(0xff90baff)),SizedBox(height:12),Text('No bills yet',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Tap Add bill to save the first expense.',style:TextStyle(color:Colors.white60))])) else ...items.map((b)=>Padding(padding:const EdgeInsets.only(bottom:10),child:BillTile(bill:b,trip:trip)))
        ]);
      })
    );
  }
}
class ReceiptImage extends StatefulWidget {
  const ReceiptImage({required this.path,this.fit=BoxFit.cover,this.iconSize=28,super.key});
  final String path; final BoxFit fit; final double iconSize;
  @override State<ReceiptImage> createState()=>_ReceiptImageState();
}
class _ReceiptImageState extends State<ReceiptImage>{
  Future<String>? url;
  @override void initState(){super.initState();if(widget.path.isNotEmpty)url=Supabase.instance.client.storage.from('receipts').createSignedUrl(widget.path,3600);}
  @override Widget build(BuildContext context){if(widget.path.isEmpty)return Icon(CupertinoIcons.doc_text_viewfinder,size:widget.iconSize);return FutureBuilder<String>(future:url,builder:(context,snap){if(snap.connectionState!=ConnectionState.done)return const Center(child:CupertinoActivityIndicator());if(snap.hasError||!snap.hasData)return Icon(CupertinoIcons.exclamationmark_triangle,size:widget.iconSize);return Image.network(snap.data!,fit:widget.fit,width:double.infinity,height:double.infinity,errorBuilder:(_,__,___)=>Icon(CupertinoIcons.exclamationmark_triangle,size:widget.iconSize));});}
}
class BillTile extends StatelessWidget {
  const BillTile({required this.bill,required this.trip,super.key}); final Bill bill; final Trip trip;
  @override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>BillDetailPage(bill:bill,trip:trip))),child:GlassCard(padding:const EdgeInsets.all(12),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(12),child:Container(width:54,height:68,color:const Color(0xff324c72),child:ReceiptImage(path:bill.receiptPath))),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(bill.merchant,style:const TextStyle(fontWeight:FontWeight.w900)),Text('${bill.category} - ${bill.dateLabel}',style:const TextStyle(color:Colors.white60)),const Text('Synced',style:TextStyle(color:Color(0xff72e7b4),fontSize:12))])),Text(bill.amountLabel,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(width:4),const Icon(CupertinoIcons.chevron_right,size:14)])));
}
class BillDetailPage extends StatefulWidget {const BillDetailPage({required this.bill,required this.trip,super.key});final Bill bill;final Trip trip;@override State<BillDetailPage> createState()=>_BillDetailPageState();}
class _BillDetailPageState extends State<BillDetailPage>{
  bool deleting=false;
  Future<void> deleteBill() async {setState(()=>deleting=true);try{final uid=FirebaseAuth.instance.currentUser!.uid;if(widget.bill.receiptPath.isNotEmpty)await Supabase.instance.client.storage.from('receipts').remove([widget.bill.receiptPath]);final db=FirebaseFirestore.instance;final tripRef=db.collection('users').doc(uid).collection('trips').doc(widget.trip.id);final billRef=tripRef.collection('bills').doc(widget.bill.id);await db.runTransaction((tx)async{final snap=await tx.get(tripRef);final d=snap.data()??{};final count=((d['billCount']as num?)?.toInt()??1)-1;final total=((d['totalMinor']as num?)?.toInt()??widget.bill.amountMinor)-widget.bill.amountMinor;tx.delete(billRef);tx.update(tripRef,{'billCount':count<0?0:count,'totalMinor':total<0?0:total,'totalLabel':total<=0?'No expenses':'${widget.bill.currency} ${(total/100).toStringAsFixed(2)}','updatedAt':FieldValue.serverTimestamp()});});if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}finally{if(mounted)setState(()=>deleting=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bill details'),actions:[IconButton(onPressed:deleting?null:deleteBill,icon:const Icon(CupertinoIcons.delete,color:Color(0xffff8a8a)))]),body:ListView(padding:const EdgeInsets.all(16),children:[ClipRRect(borderRadius:BorderRadius.circular(24),child:Container(height:360,color:const Color(0xff172238),child:ReceiptImage(path:widget.bill.receiptPath,fit:BoxFit.contain,iconSize:58))),const SizedBox(height:18),GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.bill.merchant,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('${widget.bill.category} - ${widget.bill.dateLabel}',style:const TextStyle(color:Colors.white60)),const SizedBox(height:16),Text(widget.bill.amountLabel,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900)),if(widget.bill.notes.isNotEmpty)...[const SizedBox(height:16),Text(widget.bill.notes)]]))]));
}
class BillsPage extends StatelessWidget {const BillsPage({super.key});@override Widget build(BuildContext context)=>PageList(title:'Recent bills',children:const [GlassCard(child:Column(children:[Icon(CupertinoIcons.map_fill,size:42,color:Color(0xff90baff)),SizedBox(height:12),Text('Bills are grouped by trip',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Open a trip to view, add, or delete its bills.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60))]))]);}
class NewTripPage extends StatefulWidget { const NewTripPage({super.key}); @override State<NewTripPage> createState()=>_NewTripPageState(); }
class _NewTripPageState extends State<NewTripPage>{
  final name=TextEditingController(); final destination=TextEditingController(); final currency=TextEditingController(text:'INR'); final notes=TextEditingController(); bool saving=false;
  @override void dispose(){name.dispose();destination.dispose();currency.dispose();notes.dispose();super.dispose();}
  Future<void> save() async { if(name.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a trip name.')));return;} setState(()=>saving=true); try { final user=FirebaseAuth.instance.currentUser!; final db=FirebaseFirestore.instance; await db.collection('users').doc(user.uid).set({'displayName':user.displayName,'email':user.email,'photoUrl':user.photoURL,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true)); await db.collection('users').doc(user.uid).collection('trips').add({'name':name.text.trim(),'destination':destination.text.trim(),'defaultCurrency':currency.text.trim().toUpperCase().isEmpty?'INR':currency.text.trim().toUpperCase(),'notes':notes.text.trim(),'status':'active','billCount':0,'totalMinor':0,'totalLabel':'No expenses','dateLabel':'Dates not set','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()}); if(mounted) Navigator.pop(context); } on FirebaseException catch(e){if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message??e.code)));} finally {if(mounted)setState(()=>saving=false);} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('New trip')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Trip name *',prefixIcon:Icon(CupertinoIcons.map))),const SizedBox(height:14),TextField(controller:destination,decoration:const InputDecoration(labelText:'Destination (optional)',prefixIcon:Icon(CupertinoIcons.location))),const SizedBox(height:14),TextField(controller:currency,decoration:const InputDecoration(labelText:'Default currency',hintText:'INR')),const SizedBox(height:14),TextField(controller:notes,maxLines:4,decoration:const InputDecoration(labelText:'Notes (optional)')),const SizedBox(height:20),FilledButton(onPressed:saving?null:save,child:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(saving?'Creating...':'Create trip')))]));
}
class AddBillPage extends StatefulWidget {const AddBillPage({this.trip,super.key});final Trip? trip;@override State<AddBillPage> createState()=>_AddBillPageState();}
class _AddBillPageState extends State<AddBillPage>{
  final merchant=TextEditingController();final amount=TextEditingController();final currency=TextEditingController(text:'INR');final category=TextEditingController(text:'Meals');final notes=TextEditingController();bool saving=false;XFile? receipt;
  @override void dispose(){merchant.dispose();amount.dispose();currency.dispose();category.dispose();notes.dispose();super.dispose();}
  Future<void> pick(ImageSource source)async{final file=await ImagePicker().pickImage(source:source,imageQuality:82,maxWidth:2400);if(file!=null&&mounted)setState(()=>receipt=file);}
  void choosePhoto(){showModalBottomSheet(context:context,builder:(context)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(CupertinoIcons.camera_fill),title:const Text('Take photograph'),onTap:(){Navigator.pop(context);pick(ImageSource.camera);}),ListTile(leading:const Icon(CupertinoIcons.photo),title:const Text('Choose from gallery'),onTap:(){Navigator.pop(context);pick(ImageSource.gallery);})])));}
  Future<void> save()async{if(widget.trip==null)return;final value=double.tryParse(amount.text.trim().replaceAll(',',''));if(merchant.text.trim().isEmpty||value==null||value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a merchant and valid amount.')));return;}if(receipt==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Take or choose a receipt photograph.')));return;}setState(()=>saving=true);String? uploaded;try{final uid=FirebaseAuth.instance.currentUser!.uid;final db=FirebaseFirestore.instance;final tripRef=db.collection('users').doc(uid).collection('trips').doc(widget.trip!.id);final billRef=tripRef.collection('bills').doc();final minor=(value*100).round();final code=currency.text.trim().toUpperCase().isEmpty?'INR':currency.text.trim().toUpperCase();final Uint8List bytes=await receipt!.readAsBytes();if(bytes.lengthInBytes>5*1024*1024)throw Exception('Receipt remains larger than 5 MB. Choose a smaller image.');uploaded='$uid/${widget.trip!.id}/${billRef.id}/receipt.jpg';await Supabase.instance.client.storage.from('receipts').uploadBinary(uploaded,bytes,fileOptions:const FileOptions(contentType:'image/jpeg',upsert:false));await db.runTransaction((tx)async{final snap=await tx.get(tripRef);final d=snap.data()??{};final count=(d['billCount']as num?)?.toInt()??0;final total=(d['totalMinor']as num?)?.toInt()??0;tx.set(billRef,{'merchant':merchant.text.trim(),'amountMinor':minor,'currency':code,'category':category.text.trim().isEmpty?'Other':category.text.trim(),'notes':notes.text.trim(),'dateLabel':'Today','status':'synced','receiptPath':uploaded,'imageProvider':'supabase','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});final next=total+minor;tx.update(tripRef,{'billCount':count+1,'totalMinor':next,'totalLabel':'$code ${(next/100).toStringAsFixed(2)}','updatedAt':FieldValue.serverTimestamp()});});if(mounted)Navigator.pop(context);}catch(e){if(uploaded!=null){try{await Supabase.instance.client.storage.from('receipts').remove([uploaded]);}catch(_){}}if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save receipt: $e')));}finally{if(mounted)setState(()=>saving=false);}}
  @override Widget build(BuildContext context){if(widget.trip==null)return PageList(title:'Add bill',children:const [GlassCard(child:Column(children:[Icon(CupertinoIcons.map,size:44,color:Color(0xff90baff)),SizedBox(height:12),Text('Choose a trip first',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Open a trip and tap Add bill.',style:TextStyle(color:Colors.white60))]))]);return Scaffold(appBar:AppBar(title:const Text('Add bill')),body:ListView(padding:const EdgeInsets.all(16),children:[Text(widget.trip!.name,style:const TextStyle(color:Color(0xff90baff),fontWeight:FontWeight.w900)),const SizedBox(height:14),InkWell(onTap:saving?null:choosePhoto,borderRadius:BorderRadius.circular(22),child:ClipRRect(borderRadius:BorderRadius.circular(22),child:Container(height:190,width:double.infinity,color:Colors.white.withValues(alpha:.06),child:receipt==null?const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(CupertinoIcons.camera_fill,size:42),SizedBox(height:8),Text('Take or choose receipt',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:4),Text('Required - compressed below 5 MB',style:TextStyle(color:Colors.white60))]):Image.network(receipt!.path,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Text('Receipt selected')))))),const SizedBox(height:16),TextField(controller:merchant,decoration:const InputDecoration(labelText:'Merchant *')),const SizedBox(height:14),Row(children:[Expanded(flex:2,child:TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount *'))),const SizedBox(width:10),Expanded(child:TextField(controller:currency,decoration:const InputDecoration(labelText:'Currency')))]),const SizedBox(height:14),TextField(controller:category,decoration:const InputDecoration(labelText:'Category')),const SizedBox(height:14),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Notes')),const SizedBox(height:20),FilledButton(onPressed:saving?null:save,child:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(saving?'Uploading receipt...':'Save bill and receipt')))]));}
}
class ProfilePage extends StatelessWidget {const ProfilePage({required this.user,super.key});final User user;Future<void> logout()async{await GoogleSignIn.instance.signOut();await FirebaseAuth.instance.signOut();}@override Widget build(BuildContext context)=>PageList(title:'Profile',children:[GlassCard(child:Row(children:[CircleAvatar(radius:32,backgroundImage:user.photoURL==null?null:NetworkImage(user.photoURL!),child:user.photoURL==null?const Icon(CupertinoIcons.person_fill):null),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(user.displayName??'Google user',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text(user.email??'',style:const TextStyle(color:Colors.white60))]))])),const SizedBox(height:18),GlassCard(child:ListTile(onTap:logout,leading:const Icon(CupertinoIcons.square_arrow_right,color:Color(0xffff8a8a)),title:const Text('Sign out',style:TextStyle(color:Color(0xffff8a8a)))))]);}

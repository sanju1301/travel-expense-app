import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
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

class Trip { const Trip(this.name,this.place,this.dates,this.total,this.count,this.active); final String name,place,dates,total; final int count; final bool active; }
const trips=[Trip('Pune Office Visit','Pune, Maharashtra','15-18 Nov','Rs 12,480',8,true),Trip('Chennai Weekend','Chennai, Tamil Nadu','22-24 Nov','Rs 4,260',4,true),Trip('Germany Travel','Munich, Germany','04-11 Oct','EUR 1,842',12,false)];
class Bill { const Bill(this.name,this.meta,this.amount,this.color); final String name,meta,amount; final Color color; }
const bills=[Bill('Grand Business Hotel','Hotel - 15 Nov','Rs 8,950',Color(0xff324c72)),Bill('City Taxi','Transport - 15 Nov','Rs 1,280',Color(0xff294b41)),Bill('Restaurant','Meals - 16 Nov','Rs 845',Color(0xff5a3d52))];

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});
  @override Widget build(BuildContext context) => PageList(title:'Trips',action:IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NewTripPage())),icon:const Icon(CupertinoIcons.add)),children:[
    GlassCard(child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ready for a new journey?',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Create a trip, then keep every bill together.',style:TextStyle(color:Colors.white60))])),const SizedBox(width:12),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NewTripPage())),child:const Text('New trip'))])),
    const SizedBox(height:24),const Text('Active',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:12),
    ...trips.map((t)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TripCard(trip:t))),
  ]);
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
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(trip.name)),floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddBillPage())),icon:const Icon(CupertinoIcons.camera_fill),label:const Text('Add bill')),body:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
    GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(trip.place,style:const TextStyle(color:Colors.white60)),const SizedBox(height:6),Text(trip.total,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900)),Text('${trip.count} bills - ${trip.dates}',style:const TextStyle(color:Colors.white60))])),const SizedBox(height:22),const Text('Bills',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:12),...bills.map((b)=>Padding(padding:const EdgeInsets.only(bottom:10),child:BillTile(bill:b)))
  ]));
}
class BillTile extends StatelessWidget {
  const BillTile({required this.bill,super.key});final Bill bill;
  @override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>BillDetailPage(bill:bill))),child:GlassCard(padding:const EdgeInsets.all(12),child:Row(children:[Container(width:54,height:68,decoration:BoxDecoration(color:bill.color,borderRadius:BorderRadius.circular(12)),child:const Icon(CupertinoIcons.doc_text_viewfinder)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(bill.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text(bill.meta,style:const TextStyle(color:Colors.white60)),const Text('Synced',style:TextStyle(color:Color(0xff72e7b4),fontSize:12))])),Text(bill.amount,style:const TextStyle(fontWeight:FontWeight.w900)),const Icon(CupertinoIcons.chevron_right,size:14)])));
}
class BillDetailPage extends StatelessWidget {
  const BillDetailPage({required this.bill,super.key});final Bill bill;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bill details')),body:ListView(padding:const EdgeInsets.all(16),children:[Container(height:300,decoration:BoxDecoration(color:bill.color,borderRadius:BorderRadius.circular(24)),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(CupertinoIcons.doc_text_viewfinder,size:58),SizedBox(height:12),Text('Receipt preview',style:TextStyle(fontWeight:FontWeight.w900)),Text('Camera upload comes next',style:TextStyle(color:Colors.white60))])),const SizedBox(height:18),GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(bill.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text(bill.meta,style:const TextStyle(color:Colors.white60)),const SizedBox(height:16),Text(bill.amount,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900))]))]));
}
class BillsPage extends StatelessWidget { const BillsPage({super.key}); @override Widget build(BuildContext context)=>PageList(title:'Recent bills',children:[const TextField(decoration:InputDecoration(hintText:'Search bills',prefixIcon:Icon(CupertinoIcons.search))),const SizedBox(height:18),...bills.map((b)=>Padding(padding:const EdgeInsets.only(bottom:10),child:BillTile(bill:b)))]); }
class NewTripPage extends StatefulWidget { const NewTripPage({super.key}); @override State<NewTripPage> createState()=>_NewTripPageState(); }
class _NewTripPageState extends State<NewTripPage>{final name=TextEditingController();@override void dispose(){name.dispose();super.dispose();}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('New trip')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Trip name *',prefixIcon:Icon(CupertinoIcons.map))),const SizedBox(height:14),const TextField(decoration:InputDecoration(labelText:'Destination (optional)',prefixIcon:Icon(CupertinoIcons.location))),const SizedBox(height:14),const TextField(decoration:InputDecoration(labelText:'Default currency',hintText:'INR')),const SizedBox(height:14),const TextField(maxLines:4,decoration:InputDecoration(labelText:'Notes (optional)')),const SizedBox(height:20),FilledButton(onPressed:(){if(name.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a trip name.')));return;}Navigator.pop(context);},child:const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('Create trip')))]));}
class AddBillPage extends StatelessWidget {const AddBillPage({super.key});@override Widget build(BuildContext context)=>PageList(title:'Add bill',children:[Container(height:180,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.06),borderRadius:BorderRadius.circular(22)),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(CupertinoIcons.camera_fill,size:44),Text('Photograph receipt',style:TextStyle(fontWeight:FontWeight.w900)),Text('Camera integration comes next',style:TextStyle(color:Colors.white60))])),const SizedBox(height:16),const TextField(decoration:InputDecoration(labelText:'Merchant')),const SizedBox(height:14),const TextField(keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Amount')),const SizedBox(height:14),const TextField(decoration:InputDecoration(labelText:'Category'))]);}
class ProfilePage extends StatelessWidget {const ProfilePage({required this.user,super.key});final User user;Future<void> logout()async{await GoogleSignIn.instance.signOut();await FirebaseAuth.instance.signOut();}@override Widget build(BuildContext context)=>PageList(title:'Profile',children:[GlassCard(child:Row(children:[CircleAvatar(radius:32,backgroundImage:user.photoURL==null?null:NetworkImage(user.photoURL!),child:user.photoURL==null?const Icon(CupertinoIcons.person_fill):null),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(user.displayName??'Google user',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text(user.email??'',style:const TextStyle(color:Colors.white60))]))])),const SizedBox(height:18),GlassCard(child:ListTile(onTap:logout,leading:const Icon(CupertinoIcons.square_arrow_right,color:Color(0xffff8a8a)),title:const Text('Sign out',style:TextStyle(color:Color(0xffff8a8a)))))]);}

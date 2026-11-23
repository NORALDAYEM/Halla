// This application targets Flutter Web.
import 'dart:html' as html;
import 'package:flutter/material.dart';

const ink = Color(0xff18141c);
const paper = Color(0xfffff4eb);
const coral = Color(0xffffa081);
const lilac = Color(0xffc7acf6);

void main() => runApp(const Halla());
void openApp(String destination) {
  final uri = Uri.base.resolve('../app.html').replace(queryParameters: {'view': destination});
  html.window.location.assign(uri.toString());
}

class Halla extends StatelessWidget {
  const Halla({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'هلاا',
    theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: ink),
    home: const Directionality(textDirection: TextDirection.rtl, child: Welcome()),
  );
}

// A microphone capsule forms the body of a game pad.
class Emblem extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 64, size.height / 64);
    final fill = Paint()..color = coral;
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3,3,58,58),const Radius.circular(19)),fill);
    final line = Paint()..color = ink..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 3.5;
    final pad = Path()..moveTo(13,37)..quadraticBezierTo(15,25,22,26)..quadraticBezierTo(32,30,42,26)..quadraticBezierTo(49,25,51,39)..quadraticBezierTo(53,50,44,44)..lineTo(38,39)..lineTo(26,39)..lineTo(20,44)..quadraticBezierTo(10,50,13,37)..close();
    c.drawPath(pad,line); c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(27,12,10,17),const Radius.circular(5)),line);
    c.drawLine(const Offset(19,34),const Offset(25,34),line);c.drawLine(const Offset(22,31),const Offset(22,37),line);
    c.drawCircle(const Offset(40,35),2,Paint()..color=ink);c.drawCircle(const Offset(45,32),2,Paint()..color=ink);
  }
  @override
  bool shouldRepaint(Emblem oldDelegate) => false;
}

class Lobby extends StatelessWidget {
  const Lobby({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child:LayoutBuilder(builder:(context,box){
    final wide=box.maxWidth>=760;
    return SingleChildScrollView(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1180),child:Padding(
      padding: EdgeInsets.symmetric(horizontal:wide?40:20,vertical:24),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[CustomPaint(size:const Size.square(50),painter:Emblem()),const SizedBox(width:10),const Text('هلاا',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900,color:paper)),const Spacer(),
          OutlinedButton.icon(onPressed:()=>openApp('login'),icon:const Icon(Icons.person_outline),label:const Text('دخول الأعضاء'),style:OutlinedButton.styleFrom(foregroundColor:paper))]),
        SizedBox(height:wide?46:28),Text('الصوت واللعب',style:TextStyle(fontSize:wide?54:36,fontWeight:FontWeight.w900,color:paper,height:1.35)),
        const SizedBox(height:18),
        if(wide) const Row(children:[Expanded(child:ChannelCard(voice:true)),SizedBox(width:18),Expanded(child:ChannelCard(voice:false))])
        else const Column(children:[ChannelCard(voice:true),SizedBox(height:14),ChannelCard(voice:false)]),
        const SizedBox(height:26),const Divider(color:Color(0xff443944)),Wrap(spacing:12,runSpacing:8,children:[
          TextButton.icon(onPressed:()=>openApp('store'),icon:const Icon(Icons.card_giftcard),label:const Text('متجر الهدايا')),
          TextButton.icon(onPressed:()=>openApp('home'),icon:const Icon(Icons.explore_outlined),label:const Text('تصفح هلاا كضيف'))]),
      ]),
    ))));
  })));
}

class ChannelCard extends StatelessWidget {
  final bool voice;
  const ChannelCard({super.key,required this.voice});
  @override
  Widget build(BuildContext context) {
    final title=voice?'الغرف الصوتية':'صالة الألعاب';
    final action=voice?'استكشف الغرف':'اختر لعبة';
    final color=voice?coral:lilac;
    return Semantics(button:true,label:'$title، $action',child:Material(color:ink,borderRadius:BorderRadius.circular(24),clipBehavior:Clip.antiAlias,
      child:InkWell(onTap:()=>openApp(voice?'rooms':'games'),child:ExcludeSemantics(child:AspectRatio(aspectRatio:MediaQuery.sizeOf(context).width>=760?1.22:1.52,
      child:Stack(fit:StackFit.expand,children:[
        Image.asset('art/${voice?'voice':'games'}.jpg',fit:BoxFit.cover,alignment:const Alignment(0,-.12)),
        const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0x12100c16),Color(0xf9110c17)],stops:[0,.35,1]))),
        Positioned(bottom:20,right:22,left:22,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(title,style:const TextStyle(fontSize:29,fontWeight:FontWeight.w900,color:Colors.white)),
            Text(action,style:TextStyle(color:color,fontSize:16,fontWeight:FontWeight.bold))])),
          CircleAvatar(backgroundColor:color,foregroundColor:ink,child:const Icon(Icons.arrow_back))])),
      ]))))));
  }
}

class Welcome extends StatelessWidget {
  const Welcome({super.key});
  @override
  Widget build(BuildContext context) {
    final wide=MediaQuery.sizeOf(context).width>=760;
    final photo=Image.asset('art/lounge.jpg',fit:BoxFit.cover,alignment:const Alignment(0,-.18));
    final brand=Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      CustomPaint(size:const Size.square(56),painter:Emblem()),const SizedBox(width:12),
      const Text('هلاا',style:TextStyle(fontSize:42,color:paper,fontWeight:FontWeight.w900))]);
    final actions=ConstrainedBox(constraints:const BoxConstraints(maxWidth:370),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('غرف صوتية وألعاب',textAlign:TextAlign.center,style:TextStyle(fontSize:29,color:paper,fontWeight:FontWeight.bold)),
      const SizedBox(height:22),FilledButton.icon(onPressed:()=>openApp('login'),style:FilledButton.styleFrom(minimumSize:const Size(0,56),backgroundColor:coral,foregroundColor:ink),icon:const Icon(Icons.mail_outline),label:const Text('الدخول بالبريد الإلكتروني')),
      const SizedBox(height:10),OutlinedButton.icon(style:OutlinedButton.styleFrom(minimumSize:const Size(0,54),foregroundColor:paper,side:const BorderSide(color:Color(0xffa797a9))),onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const Directionality(textDirection:TextDirection.rtl,child:Lobby()))),icon:const Icon(Icons.headphones),label:const Text('تصفح كضيف')),
    ]));
    if(wide)return Scaffold(body:Row(children:[Expanded(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[brand,const SizedBox(height:48),actions])))),Expanded(child:SizedBox.expand(child:photo))]));
    return Scaffold(body:Stack(fit:StackFit.expand,children:[photo,const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x44100016),Colors.transparent,Color(0xf9170d1c)],stops:[0,.38,1]))),SafeArea(child:LayoutBuilder(builder:(context,size)=>SingleChildScrollView(child:ConstrainedBox(constraints:BoxConstraints(minHeight:size.maxHeight),child:Padding(padding:const EdgeInsets.fromLTRB(24,24,24,28),child:Column(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[brand,const SizedBox(height:42),actions]))))))]));
  }
}

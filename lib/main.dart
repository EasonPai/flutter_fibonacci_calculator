import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';

void main() {
	runApp(new MyApp());
}

class MyApp extends StatelessWidget {
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: 'Flutter Fibonacci Calculator',
			theme: new ThemeData(
				primarySwatch: Colors.blue,
				accentColor: Colors.greenAccent,
			),
			home: new MyHomePage(title: 'Flutter Fibonacci Calculator'),
		);
	}
}

class MyHomePage extends StatefulWidget {
	MyHomePage({Key key, this.title}) : super(key: key);

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

	ReceivePort _main_receive;
	SendPort _remote_sender;
	Isolate _isolate;

	String _result = "";
	int _input = 40;
	int _output;

	@override
	void initState() {
		super.initState();

		// init isolate

		initIsolate();
	}

	@override
	void dispose() {
		super.dispose();

		if (_isolate != null) {
			_isolate.kill(priority: Isolate.IMMEDIATE);
			_isolate = null;
		}
	}

	static void _isolateEntryPoint(SendPort sender) {
		final remoteReceive = new ReceivePort();
		final mainSender = sender;
		mainSender.send(remoteReceive.sendPort);
		remoteReceive.listen((message) {
			print("main message = $message");
			mainSender.send(fibonacci(message));
		});
	}

	@override
	Widget build(BuildContext context) {
		return new Scaffold(
			appBar: new AppBar(
				title: new Text(widget.title),
			),
			body:

			new Container(
					padding: const EdgeInsets.all(12.0),
					child: new Column(
							mainAxisAlignment: MainAxisAlignment.start,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: <Widget>[
								const LinearProgressIndicator(),
								new TextField(
									decoration: new InputDecoration(
										hintText: '40',
										labelText: 'Type a number',
									),
									onChanged: (String value) {
										_input = int.parse(value ?? 0);
									},
								),
								new Center(
										child: new Row(
												mainAxisAlignment: MainAxisAlignment.spaceAround,
												children: <Widget>[
													new Text("Run with"),
													new RaisedButton(
															child: new Text("MULTI-THREAD"),
															onPressed: _onMulti),
													new RaisedButton(
															child: new Text("MAIN-THREAD"),
															onPressed: _onMain),
												]
										)
								),
								new Container(
									padding: const EdgeInsets.only(top: 24.0),
									child: new Text(_result),
								),
							]
					)
			),
		);
	}

	void _onMulti() {
		_output = null;
		updateView();
		_remote_sender.send(_input);
	}

	void _onMain() {
		_output = _input;
		_output = fibonacci(_output);
		updateView();
	}

	void updateView() {
		setState(() {
			_result = "Fibonacci ($_input) outputs ${(_output==null)? '...':_output}";
		});
	}
	static int fibonacci(int n) {
		return n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2);
	}

  void initIsolate() {

	  _main_receive = new ReceivePort();
	  Isolate.spawn(_isolateEntryPoint, _main_receive.sendPort).then<Null>((Isolate isolate) {
		  _isolate = isolate;
	  });

	  _main_receive.listen((message) {
		  if (message is SendPort) {
			  _remote_sender = message;
		  } else {
			  print("remote message = $message");
			  _output = message;
			  updateView();
		  }
	  });

	  updateView();
  }

}
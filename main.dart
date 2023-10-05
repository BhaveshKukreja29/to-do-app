import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  await Hive.initFlutter();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  runApp(MyApp());
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late bool isCompleted;

  Task(this.name, this.isCompleted);
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final name = reader.readString();
    final isCompleted = reader.readBool();
    return Task(name, isCompleted);
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.name);
    writer.writeBool(obj.isCompleted);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do App',
      theme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

enum SortOrder { ascending, descending }

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int finishedTasksCount = 0;
  int unfinishedTasksCount = 0;
  SortOrder currentSortOrder = SortOrder.ascending;
  final TextEditingController textEditingcontroller = TextEditingController();
  final TextEditingController search_controller = TextEditingController();
  final Box<Task> _taskBox = Hive.box<Task>('tasks');
  List<Task> searchresults = [];

  @override
  void initState() {
    super.initState();
    search_controller.addListener(searchbarfunction);
    searchresults = _taskBox.values.toList();
    updatetaskcounts();
  }

  void searchbarfunction() {
    final searchText = search_controller.text.toLowerCase();
    setState(() {
      if (searchText.isEmpty) {
        searchresults = _taskBox.values.toList();
      } else {
        searchresults = _taskBox.values
            .where((task) => task.name.toLowerCase().contains(searchText))
            .toList();
      }
    });
  }

  void updatetaskcounts() {
    finishedTasksCount = searchresults.where((task) => task.isCompleted).length;
    unfinishedTasksCount = searchresults.length - finishedTasksCount;
  }


  void sorttasks() {
    setState(() {
      if (currentSortOrder == SortOrder.ascending) {
        searchresults.sort((a, b) => a.name.compareTo(b.name));
        currentSortOrder = SortOrder.descending;
      } else {
        searchresults.sort((a, b) => b.name.compareTo(a.name));
        currentSortOrder = SortOrder.ascending;
      }
    });
  }


  void addtaskfunction(String taskName) {
    if (taskName.isNotEmpty) {
      final task = Task(taskName, false);
      _taskBox.add(task);
      textEditingcontroller.clear();
      setState(() {
        searchresults.add(task);
      });
      updatetaskcounts();
    }
  }

  void checkboxfunction(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      task.save();
      updatetaskcounts();
    });

  }

  void deletefunction(Task task) {
    setState(() {
      task.delete();
      searchresults.remove(task);
      updatetaskcounts();
    });
  }

  void editfunction(Task task) {
    final TextEditingController editController = TextEditingController(text: task.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Your Task', textAlign: TextAlign.center,),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: InputDecoration(hintText: 'Edit task name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20)
                )),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Custom button color
              ),
              onPressed: () {
                final newName = editController.text;
                if (newName.isNotEmpty) {
                  setState(() {
                    task.name = newName;
                    task.save();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            (Text('To Do App',style: TextStyle(fontSize: 25))),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: Icon(Icons.sort_by_alpha), onPressed: sorttasks)],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Finished Tasks: $finishedTasksCount',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),),),
              Spacer(),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Unfinished Tasks: $unfinishedTasksCount',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),),),
            ],
          ),
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingcontroller,
                    decoration: InputDecoration(
                        hintText: 'Add a new task',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)
                        )
                    ),
                  ),
                ),
                IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () => addtaskfunction(textEditingcontroller.text),
                  icon: Icon(Icons.add),


                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(fontSize: 20),
              controller: search_controller,
              decoration: InputDecoration(
                  hintText: 'Search tasks',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)
                  )
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchresults.length,
              itemBuilder: (context, index) {
                final task = searchresults[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,

                      ),
                    ),
                    subtitle: Text(
                      task.isCompleted ? 'Complete!' : 'Incomplete!!',
                      style: TextStyle(fontSize: 15,
                        color: task.isCompleted ? Colors.green : Colors.red,
                      ),
                    ),
                    leading: Checkbox(
                      checkColor: Colors.black,
                      activeColor: Colors.blue,
                      value: task.isCompleted,
                      onChanged: (_) => checkboxfunction(task),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => editfunction(task),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deletefunction(task),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

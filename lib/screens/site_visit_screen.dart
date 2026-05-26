import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_session.dart';
import '../models/site_visit_model.dart';

class SiteVisitScreen extends StatefulWidget {
  final SiteVisitModel? visit; // ✅ ADD THIS
  
  const SiteVisitScreen({super.key, this.visit}); // ✅ UPDATE CONSTRUCTOR




  @override
  State<SiteVisitScreen> createState() => _SiteVisitScreenState();
}

class _SiteVisitScreenState extends State<SiteVisitScreen> {

  final _formKey = GlobalKey<FormState>();
  

  // 🔹 Controllers
  final mobileController = TextEditingController();
  final nameController = TextEditingController();
  final remarksController = TextEditingController();

  // 🔹 Dropdown Values
  String? selectedDivision;
  String? selectedProduct;
  String? selectedBDM;
  String? selectedStatus;
  String? visitDoneBy;

  DateTime selectedDate = DateTime.now();

  // 🔹 Master Data
  List divisions = [];
  List products = [];
  List bdms = [];
  
  final List<String> statusList = [
    "Hot Closing",
    "Hot",
    "Medium",
    "Cold",
    "Not Interested"
  ];  

  bool isLoading = false;

  final String baseUrl = "https://backoffice.thecubeclub.co/apis/";

@override
void initState() {
  super.initState();
  fetchMasterData();

  if (widget.visit != null) {
    nameController.text = widget.visit!.name;
    mobileController.text = widget.visit!.mobile;
    remarksController.text = widget.visit!.remarks;    

    selectedProduct = widget.visit!.project;
    selectedStatus = widget.visit!.status;

    // ⛔ DON'T set BDM here directly
    // we will map it AFTER master loads

    visitDoneBy = widget.visit!.visitDoneBy ?? "";
  }
}



  // ================= FETCH MASTER =================
  Future<void> fetchMasterData() async {
    try {
      final res = await http.get(Uri.parse("${baseUrl}site_visit_master.php"));
      final data = json.decode(res.body);

      if (data['success']) {
        //print(data);

        setState(() {
          divisions = data['data']['division'];
          products  = data['data']['products'];
          bdms      = data['data']['bdm'];
          //statusList= data['data']['status'];
        });

if (widget.visit != null) {
  // 🔥 MATCH BDM NAME → ID
  final matchBDM = bdms.where((b) {
    return b['name'] == widget.visit!.bdm;
  }).toList();

  if (matchBDM.isNotEmpty) {
    selectedBDM = matchBDM.first['id'].toString();
  }

  // 🔥 MATCH PRODUCT (already string, usually safe)
  final matchProduct = products.where((p) {
    return p['name'] == widget.visit!.project;
  }).toList();

  if (matchProduct.isNotEmpty) {
    selectedProduct = matchProduct.first['name'];
  }
}

if (widget.visit != null) {

  // ✅ DIVISION MATCH (IMPORTANT)
  final matchDivision = divisions.where((d) {
    return d['name'] == widget.visit!.division;
  }).toList();

  if (matchDivision.isNotEmpty) {
    selectedDivision = matchDivision.first['id'].toString();
  }

}


      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ================= FETCH CONTACT =================
 Future<void> fetchContact(String mobile) async {
  try {
    final res = await http.get(
      Uri.parse("${baseUrl}get_contact_info.php?contact_no=$mobile"),
    );

    final data = json.decode(res.body);

    if (data['found']) {
      setState(() {

        // ✅ Name
        nameController.text = data['data']['guest_name'] ?? '';

        // ================= PRODUCT (FIXED) =================
        final apiProduct = data['data']['product_name'] ?? '';

        final productMatchList = products.where((p) {
          final name = p['name'].toString().toLowerCase();
          return apiProduct.toLowerCase().contains(name);
        }).toList();

        if (productMatchList.isNotEmpty) {
          selectedProduct = productMatchList.first['name'];
        } else {
          selectedProduct = null;
        }

        // ================= BDM =================
        final bdmMatchList = bdms.where((b) {
          return b['name'] == data['data']['bdm1_name'];
        }).toList();

        if (bdmMatchList.isNotEmpty) {
          selectedBDM = bdmMatchList.first['id'].toString(); // ✅ MUST BE STRING ID
        } else {
          selectedBDM = null;
        }        

        // ================= DIVISION =================
        final divisionMatchList = divisions.where((d) {
          return d['id'].toString() ==
              data['data']['division_id']?.toString();
        }).toList();

        if (divisionMatchList.isNotEmpty) {
          selectedDivision = divisionMatchList.first['id'].toString();
        } else {
          selectedDivision = null;
        }

      });
    }
  } catch (e) {
    debugPrint("Fetch error: $e");
  }
}


  // ================= SUBMIT =================
  Future<void> submitForm() async {

    print("🚀 SUBMIT CALLED");

    if (isLoading) return; // 🔥 prevents double hit

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final requestBody = {
      "id": widget.visit != null ? widget.visit!.id.toString() : "0",
      "entry_date": selectedDate.toString().split(' ')[0],
      "division_id": selectedDivision ?? "",
      "contact_no": mobileController.text ?? "",
      "guest_name": nameController.text ?? "",
      "product_name": selectedProduct ?? "",
      "bdm1_id": selectedBDM ?? "",
      "visit_done_by": visitDoneBy ?? "",
      "category": selectedStatus ?? "",
      "remarks": remarksController.text,
      "lead_id": "",
      "user_id": UserSession.bdmId.toString(),
    };

    //print("📤 REQUEST: ${json.encode(requestBody)}");


    try {
      final res = await http.post(
        Uri.parse("${baseUrl}save_site_visit.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),        
      );

      final data = json.decode(res.body);

      if (data['success']) {
          if (!mounted) return; // 🔥 IMPORTANT

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.visit == null
                  ? "✅ Site Visit Saved"
                  : "✅ Site Visit Updated"),
            ),
          );

          // 🔥 Delay pop slightly to avoid lifecycle conflict
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
 else {
        showError(data['message']);
      }

    } catch (e) {
      print("ERROR: $e");
      showError("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void clearForm() {
    mobileController.clear();
    nameController.clear();
    remarksController.clear();

    setState(() {
      selectedDivision = null;
      selectedProduct = null;
      selectedBDM = null;
      selectedStatus = null;
      visitDoneBy = null;
      selectedDate = DateTime.now();
    });
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ================= DATE PICKER =================
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Site Visit Entry"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    _card([
                      _dateField(),
                      _dropdown("Division", divisions, selectedDivision,
                          (val) => setState(() => selectedDivision = val), isId: true),
                      _mobileField(),
                      _textField("Visitor Name", nameController),
                      _dropdown("Product", products, selectedProduct,
                          (val) => setState(() => selectedProduct = val)),
                      _dropdown("BDM", bdms, selectedBDM,
                          (val) => setState(() => selectedBDM = val), isId: true),

                      _visitDoneBy(),
                      _statusDropdown(),
                      _textField("Remarks", remarksController, maxLines: 3),
                    ]),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitForm,
                        child: Text(widget.visit == null ? "Submit" : "Update"),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _dateField() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text("Visit Date"),
      subtitle: Text(selectedDate.toString().split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      onTap: pickDate,
    );
  }

  Widget _mobileField() {
    return TextFormField(
      controller: mobileController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(labelText: "Mobile Number"),
      onChanged: (val) {
        if (val.length >= 10) fetchContact(val);
      },
      validator: (val) =>
          val == null || val.length < 10 ? "Enter valid mobile" : null,
    );
  }

  Widget _textField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dropdown(String label, List list, value, Function onChanged,
    {bool isId = false}) {

  final values = list.map((e) =>
      isId ? e['id'].toString() : e['name']).toList();

  final safeValue = values.contains(value) ? value : null;

  return DropdownButtonFormField(
    value: safeValue, // ✅ prevents crash
    hint: Text(label),
    items: list.map<DropdownMenuItem>((e) {
      return DropdownMenuItem(
        value: isId ? e['id'].toString() : e['name'],
        child: Text(e['name']),
      );
    }).toList(),
    onChanged: (val) => onChanged(val),
  );
}


Widget _visitDoneBy() {
  final list = ["Kartik", "Ronak Modi"];

  final safeValue = (visitDoneBy != null && list.contains(visitDoneBy))
      ? visitDoneBy
      : null;

  return DropdownButtonFormField<String>(
    value: safeValue,
    hint: const Text("Visit Done By"),
    items: list.map((e) {
      return DropdownMenuItem<String>(
        value: e,
        child: Text(e),
      );
    }).toList(),
    onChanged: (val) => setState(() => visitDoneBy = val),
  );
}


Widget _statusDropdown() {
  final safeValue =
      (selectedStatus != null && statusList.contains(selectedStatus))
          ? selectedStatus
          : null;

  return DropdownButtonFormField<String>(
    value: safeValue,
    hint: const Text("Status"),
    items: statusList.map((e) {
      return DropdownMenuItem<String>(
        value: e,
        child: Text(e),
      );
    }).toList(),
    onChanged: (val) {
      setState(() => selectedStatus = val);
    },
  );
}


}
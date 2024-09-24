import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:sado/Paginas/Secundarias/Suppliers/createSupplier.dart';
import 'package:sado/Paginas/Secundarias/Suppliers/supplierInfo.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SuppliersCompanyPage extends StatefulWidget {
  final String idCompany;
  SuppliersCompanyPage({required this.idCompany});

  @override
  _SuppliersCompanyPageState createState() => _SuppliersCompanyPageState();
}

class _SuppliersCompanyPageState extends State<SuppliersCompanyPage> {
  TextEditingController searchController = TextEditingController();
  String? selectedSupplierIdForDeletion;
  List<dynamic> suppliers = [];
  List<dynamic> companies = [];
  List<Map<String, dynamic>> filteredSuppliers = [];
  List<int> rowsPerPageOptions = [25, 50, 100]; // For the "All" option
  List<String> selectedSupplierIds = [];
  int rowsPerPage = 25;
  int currentPage = 0; // Current page index
  bool isTrashVisible = false;
  bool isLoading = true;
  bool notExist = true;
  String? countSuppliers;
  // Sorting-related state variables
  int _sortColumnIndex = 0; // Initially sort by 'ID'
  bool _isAscending = true; // Ascending by default
  int totalPages = 0;
  List<Map<String, dynamic>> displayedSuppliers = [];

  @override
  void initState() {
    super.initState();

    fetchCountSuppliers(widget.idCompany);
    fetchSuppliers(widget.idCompany);
  }

  Future<void> fetchCountSuppliers(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    final response = await http.post(
      Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
      body: {
        'query_param': 'S0',
        'id': idCodMaster,
        'idcompany': companyId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        countSuppliers = data['supplier_count'].toString();
      });
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  Future<void> fetchSuppliers(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'S1',
          'id': idCodMaster,
          'idcompany': companyId,
          'limit': rowsPerPage.toString(),
          'page': (currentPage).toString(), // API might be using 1-based index
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          suppliers = data;
          filteredSuppliers = List<Map<String, dynamic>>.from(data);
          notExist = suppliers.isEmpty;
          isLoading = false;
           displayedSuppliers = rowsPerPage == -1
          ? filteredSuppliers
          : filteredSuppliers
              .skip(currentPage * rowsPerPage)
              .take(rowsPerPage)
              .toList();
        });
      } else {
        throw Exception('Failed to load suppliers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  void _filterCustomers() async {
    String query = searchController.text.toLowerCase();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var idCodMaster = prefs.getString("idMaster");

      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'S5',
          'id': idCodMaster,
          'idcompany': widget.idCompany,
          'op': query,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data != 0) {
            suppliers = List<Map<String, dynamic>>.from(
                data); // Update the suppliers list
            filteredSuppliers = List<Map<String, dynamic>>.from(
                data); // Update filteredSuppliers
          } else {
            suppliers = []; // Set suppliers to an empty list when data is "0"
            filteredSuppliers = []; // Ensure filteredSuppliers is an empty list
          }
          currentPage = 0; // Reset to the first page in both cases
        });
      } else {
        throw Exception('Failed to load suppliers');
      }
       displayedSuppliers = rowsPerPage == -1
          ? filteredSuppliers
          : filteredSuppliers
              .skip(currentPage * rowsPerPage)
              .take(rowsPerPage)
              .toList();
    } catch (e) {
      setState(() {});
      print('Error: $e');
    }
  }

  Future<void> deleteSupplier() async {
    final response = await http.post(
      Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
      body: {
        'query_param': 'S3',
        'id': selectedSupplierIdForDeletion,
      },
    );

    print(response.body);

    if (response.statusCode == 200) {
      _showDialog(
          context, "Supplier Deleted", "Supplier Deleted successfully.", 1);
    } else {
      _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
    }
  }

  void _showDialog(
      BuildContext context, String title, String message, int value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminDrawer(
                            currentPage: SuppliersCompanyPage(
                              idCompany: widget.idCompany,
                            ),
                            numero: 3)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text('Yes', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                secoundDialogDeleted();
              },
            ),
            TextButton(
              child: Text('No', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void secoundDialogDeleted() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you really sure?",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you really sure?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text('Yes', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                deleteSupplier();
              },
            ),
            TextButton(
              child: Text('No', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Sort Function
  void _sort<T>(Comparable<T>? Function(Map<String, dynamic> supplier) getField,
      int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;

      filteredSuppliers.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);

        // Handle null values
        if (aValue == null && bValue == null) return 0; // Both are null
        if (aValue == null) return ascending ? -1 : 1; // Treat null as smallest
        if (bValue == null) return ascending ? 1 : -1; // Treat null as smallest

        // Numeric sorting for specific column indices
        if (columnIndex == 1 || columnIndex == 4 || columnIndex == 6) {
          final aNum = num.tryParse(aValue.toString()) ?? double.nan;
          final bNum = num.tryParse(bValue.toString()) ?? double.nan;
          return ascending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
        } else {
          return ascending
              ? Comparable.compare(aValue, bValue)
              : Comparable.compare(bValue, aValue);
        }
      });
    });
  }

  String getCountry(supplier) {
    if (supplier['Country'] == null || supplier['Country'] == "") {
      return 'N/A';
    } else {
      String? countryName =
          CountryList.getCountryNameByCode(supplier['Country']);
      return countryName.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatAddress(Map<String, dynamic> supplier) {
      String address = (supplier['Address'] ?? 'N/A');
      String address2 = (supplier['Address2'] ?? '');
      if (address2 == "") {
        return "$address";
      } else {
        return "$address, $address2";
      }
    }

    int countSupplier = int.parse(countSuppliers.toString());
    totalPages = (countSupplier / rowsPerPage).ceil();

    

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notExist
              ? Center(child: Text("No Suppliers found."))
              : Column(
                  children: [
                    // Search bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth,
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Search',
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.search),
                                      onPressed:
                                          _filterCustomers, // Trigger search
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Optionally trigger search on text change
                                    _filterCustomers();
                                  },
                                ),
                              ),
                              Visibility(
                                visible: isTrashVisible,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    if (selectedSupplierIds.isNotEmpty) {
                                      _showDeleteDialog(
                                          context,
                                          "Confirmed Deleted",
                                          "Are you sure you want to delete the selected supplier?");
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 16.0),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _isAscending,
                                  columns: [
                                    DataColumn(label: Text('Select')),
                                    DataColumn(
                                      label: Text('ID'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) =>
                                                supplier['IdSupplier'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Name'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Name'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Mail'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Mail'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Phone'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Phone'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Address'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Address'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Zip Code / Postal Code'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['ZipCode'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Country'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Country'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(
                                      label: Text('Type'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (supplier) => supplier['Type'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: suppliers.map((supplier) {
                                    var countryName = getCountry(supplier);
                                    return DataRow(
                                      selected: selectedSupplierIds
                                          .contains(supplier['IdSupplier']),
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            value: selectedSupplierIds.contains(
                                                supplier['IdSupplier']),
                                            onChanged: (bool? checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  selectedSupplierIds.add(
                                                      supplier['IdSupplier']);
                                                } else {
                                                  selectedSupplierIds.remove(
                                                      supplier['IdSupplier']);
                                                }
                                                isTrashVisible =
                                                    selectedSupplierIds
                                                        .isNotEmpty;
                                              });
                                            },
                                          ),
                                        ),
                                        DataCell(Text(
                                            supplier['IdSupplier'] ?? 'N/A')),
                                        DataCell(
                                            Text(supplier['Name'] ?? 'N/A')),
                                        DataCell(
                                            Text(supplier['Mail'] ?? 'N/A')),
                                        DataCell(
                                            Text(supplier['Phone'] ?? 'N/A')),
                                        DataCell(Text(formatAddress(supplier))),
                                        DataCell(
                                            Text(supplier['ZipCode'] ?? 'N/A')),
                                        DataCell(Text(countryName ?? 'N/A')),
                                        DataCell(
                                            Text(supplier['Type'] ?? 'N/A')),
                                        DataCell(
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.of(context).push(
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder:
                                                        (BuildContext context,
                                                                _, __) =>
                                                            SupplierDetailsPage(
                                                      supplier: supplier,
                                                      idCompany:
                                                          widget.idCompany,
                                                    ),
                                                    transitionsBuilder:
                                                        (context,
                                                            animation,
                                                            secondaryAnimation,
                                                            child) {
                                                      return FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      );
                                                    },
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                setState(() {
                                                  selectedSupplierIdForDeletion =
                                                      supplier['IdSupplier'];
                                                });
                                                _showDeleteDialog(
                                                    context,
                                                    'Confirm Deletion',
                                                    'Are you sure you want to delete this supplier?');
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              return [
                                                PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('Edit'),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    leading: Icon(Icons.delete,
                                                        color: Colors.red),
                                                    title: Text('Delete'),
                                                  ),
                                                ),
                                              ];
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomAppBar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text("Rows per page: "),
                    DropdownButton<int>(
                      value: rowsPerPage,
                      items: [25, 50, 100, -1].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value == -1 ? 'All' : value.toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          rowsPerPage = newValue!;
                          currentPage = 0; // Reset to the first page
                          isLoading = true;

                          fetchCountSuppliers(widget.idCompany);
                          fetchSuppliers(widget.idCompany);
                        });
                      },
                    ),
                    SizedBox(width: 16.0),
                    Text("Page: ${currentPage + 1} of $totalPages"),
                    IconButton(
                      icon: Icon(Icons.first_page),
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                currentPage = 0;
                                isLoading = true;

                                fetchCountSuppliers(widget.idCompany);
                                fetchSuppliers(widget.idCompany);
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                currentPage--;
                                isLoading = true;

                                fetchCountSuppliers(widget.idCompany);
                                fetchSuppliers(widget.idCompany);
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios),
                      onPressed: currentPage < totalPages - 1
                          ? () {
                              setState(() {
                                currentPage++;
                                isLoading = true;

                                fetchCountSuppliers(widget.idCompany);
                                fetchSuppliers(widget.idCompany);
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.last_page),
                      onPressed: currentPage < totalPages - 1
                          ? () {
                              setState(() {
                                currentPage = totalPages - 1;
                                isLoading = true;

                                fetchCountSuppliers(widget.idCompany);
                                fetchSuppliers(widget.idCompany);
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Supplier',
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (BuildContext context, _, __) =>
                      CreateSuppliersForm(idCompany: widget.idCompany),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.refresh),
            label: 'Refresh',
            onTap: () {
              _filterCustomers(); // Refresh data
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

import 'package:flutter/material.dart';

class AddressFields extends StatefulWidget {
  final Function(String address, String province, String city, String barangay,
      String postalCode) onAddressChange;
  final bool required;

  const AddressFields({
    Key? key,
    required this.onAddressChange,
    this.required = true,
  }) : super(key: key);

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  final TextEditingController _addressController = TextEditingController();
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  final List<String> _provinces = [
    'Agusan Del Sur',
    'Surigao Del Sur',
    'Agusan Del Norte',
    'Davao Del Sur',
    'Cotabato',
    'South Cotabato',
    'Sarangani',
    'Compostela Valley',
    'Davao Del Norte',
    'Davao De Oro'
  ];

  final Map<String, List<String>> _citiesByProvince = {
    'Agusan Del Sur': ['Bayugan'],
    'Davao Del Sur': ['Davao', 'Digos'],
    'Cotabato': ['Kidapawan'],
    'South Cotabato': ['Koronadal'],
    'Davao De Oro': ['Mati'],
    'Surigao Del Sur': ['Surigao'],
    'Sultan Kudarat': ['Tacurong'],
    'Davao Del Norte': ['Tagum'],
  };

  final Map<String, List<String>> _barangaysByCity = {
    'Davao': [
      'Acacia',
      'Agdao',
      'Alambre',
      'Alejandra Navarro (Lasang)',
      'Alfonso Angliongto Sr.',
      'Angalan',
      'Atan-Awe',
      'Baganihan',
      'Bago Aplaya',
      'Bago Gallera',
      'Bago Oshiro',
      'Baguio',
      'Balingaeng',
      'Baliok',
      'Bangkas Heights',
      'Bantol',
      'Baracatan',
      'Barangay 10-A',
      'Barangay 11-B',
      'Barangay 12-B',
      'Barangay 13-B',
      'Barangay 14-B',
      'Barangay 15-B',
      'Barangay 16-B',
      'Barangay 17-B',
      'Barangay 18-B',
      'Barangay 19-B',
      'Barangay 1-A',
      'Barangay 21-C',
      'Barangay 22-C',
      'Barangay 23-C',
      'Barangay 24-C',
      'Barangay 25-C',
      'Barangay 26-C',
      'Barangay 27-C',
      'Barangay 28-C',
      'Barangay 29-C',
      'Barangay 2-A',
      'Barangay 30-D',
      'Barangay 31-D',
      'Barangay 32-D',
      'Barangay 33-D',
      'Barangay 34-D',
      'Barangay 35-D',
      'Barangay 36-D',
      'Barangay 37-D',
      'Barangay 38-D',
      'Barangay 39-D',
      'Barangay 3-A',
      'Barangay 40-D',
      'Barangay 4-A',
      'Barangay 5-A',
      'Barangay 6-A',
      'Barangay 7-A',
      'Barangay 8-A',
      'Barangay 9-A',
      'Bato',
      'Bayabas',
      'Biao Escuela',
      'Biao Guianga',
      'Bioa Joaqiun',
      'Binugao',
      'Bucana',
      'Buda',
      'Buhangin',
      'Bunawan',
      'Cabantian',
      'Cadalian',
      'Calninan',
      'Callawa',
      'Camansi',
      'Carmen',
      'Catalunan Grande',
      'Catalunan Pequeño',
      'Catigan',
      'Cawayan',
      'Centro (San Juan)',
      'Colosas',
      'Communal',
      'Crossing Bayabas',
      'Dacudao',
      'Dalag',
      'Dalagdag',
      'Daliao',
      'Daliao Plantation',
      'Datu Salumay',
      'Dominga',
      'Dumoy',
      'Eden',
      'Fatima (Benowan)',
      'Gatungan',
      'Gov. Paciano Bangoy',
      'Gov. Vicente Duterte',
      'Gumalang',
      'Gumitang',
      'Ilang',
      'Inayangan',
      'Indangan',
      'Kap. Tomas Monteverde Sr.',
      'Kilate',
      'Lacson',
      'Lamanan',
      'Lampianao',
      'Langub',
      'Lapu-Lapu',
      'Leon Garcia Sr.',
      'Lizada',
      'Los Amigos',
      'Lubogan',
      'Lumiad',
      'Ma-a',
      'Mabuhay',
      'Magsaysay',
      'Magtuod',
      'Mahayag',
      'Malabog',
      'Malagos',
      'Malamba',
      'Manambulan',
      'Mandug',
      'Manuel Guianga',
      'Mapula',
      'Marapangi',
      'Marilog',
      'Matina Aplaya',
      'Matina Biao',
      'Matina Crossing',
      'Matina Pangi',
      'Megkawayan',
      'Mintal',
      'Mudiang',
      'Mulig',
      'New Carmen',
      'New Valencia',
      'Pampanga',
      'Panacan',
      'Panalum',
      'Pandaitan',
      'Pangyan',
      'Paquibato',
      'Paradise Embak',
      'Rafael Castillo',
      'Riverside',
      'Salapawan',
      'Salaysay',
      'Saloy',
      'San Antonio',
      'San Isidro (Licanan)',
      'Santo Niño',
      'Sasa',
      'Sibulan',
      'Sirib',
      'Suawan (Tuli)',
      'Subasta',
      'Sumimao',
      'Tacunan',
      'Tagakpan',
      'Tagurano',
      'Talandang',
      'Talomo',
      'Talomo River',
      'Tamayong',
      'Tambobong',
      'Tamugan',
      'Tapak',
      'Tawan-Tawan',
      'Tibuloy',
      'Tibungco',
      'Tigatto',
      'Toril',
      'Tugbok',
      'Tungkalan',
      'Ubalde',
      'Ulas',
      'Vicente Hizon Sr.',
      'Waan',
      'Wangan',
      'Wilfredo Aquino',
      'Wines'
    ],
    'Butuan': [],
    'Bayugan': [],
    'Cabadbaran': [],
    'Digos': [],
    'Kidapawan': [],
    'Koronadal': [],
    'Mati': [],
    'Surigao': [],
    'Tacurong': [],
    'Tagum': []
  };

  final Map<String, String> _postalCodesByCity = {
    'Butuan': '8600',
    'Davao': '8000',
    'Surigao': '8400',
    'Bayugan': '8502',
    'Cabadbaran': '8605',
    'Digos': '8002',
    'Kidapawan': '9400',
    'Koronadal': '9506',
    'Mati': '8200',
    'Tacurong': '9800',
    'Tagum': '8100'
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Bldg., Block, Lot, Street Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (_selectedProvince != null && _selectedCity != null) {
              widget.onAddressChange(
                value,
                _selectedProvince!,
                _selectedCity!,
                _selectedBarangay ?? '',
                _getPostalCodeForCity(_selectedCity!),
              );
            }
          },
          validator: (value) {
            if (widget.required && (value == null || value.isEmpty)) {
              return 'Please enter your complete address';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Province Dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Province',
            border: OutlineInputBorder(),
          ),
          value: _selectedProvince,
          isExpanded: true,
          menuMaxHeight: 150, // Reduced height
          items: _provinces.map((String province) {
            return DropdownMenuItem<String>(
              value: province,
              child: Text(province),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedProvince = newValue;
              _selectedCity = null;
              _selectedBarangay = null;
            });
          },
          validator: (value) {
            if (widget.required && (value == null || value.isEmpty)) {
              return 'Please select a province';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // City Dropdown
        if (_selectedProvince != null)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            value: _selectedCity,
            isExpanded: true,
            menuMaxHeight: 150, // Reduced height
            items: _citiesByProvince[_selectedProvince]?.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList() ??
                [],
            onChanged: (String? newValue) {
              setState(() {
                _selectedCity = newValue;
                _selectedBarangay = null;
                if (newValue != null) {
                  widget.onAddressChange(
                    _addressController.text,
                    _selectedProvince!,
                    newValue,
                    '',
                    _getPostalCodeForCity(newValue),
                  );
                }
              });
            },
            validator: (value) {
              if (widget.required && (value == null || value.isEmpty)) {
                return 'Please select a city';
              }
              return null;
            },
          ),

        // Barangay Dropdown
        if (_selectedCity != null) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Barangay',
              border: OutlineInputBorder(),
            ),
            value: _selectedBarangay,
            isExpanded: true,
            menuMaxHeight: 150, // Reduced height
            items: _barangaysByCity[_selectedCity]?.map((String barangay) {
                  return DropdownMenuItem<String>(
                    value: barangay,
                    child: Text(barangay),
                  );
                }).toList() ??
                [],
            onChanged: (String? newValue) {
              setState(() {
                _selectedBarangay = newValue;
                if (newValue != null && _selectedCity != null) {
                  widget.onAddressChange(
                    _addressController.text,
                    _selectedProvince!,
                    _selectedCity!,
                    newValue,
                    _getPostalCodeForCity(_selectedCity!),
                  );
                }
              });
            },
            validator: (value) {
              if (widget.required && (value == null || value.isEmpty)) {
                return 'Please select a barangay';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  String _getPostalCodeForCity(String city) {
    return _postalCodesByCity[city] ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}

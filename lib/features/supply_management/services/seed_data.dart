import '../models/contact_person.dart';
import '../models/supplier.dart';

class SeedData {
  static List<Supplier> getInitialSuppliers() {
    final now = DateTime.now();
    return [
      Supplier(
        id: 'MSP/01',
        name: 'STS Tools',
        address:
            'Plot No. 42, Industrial Area, Phase II, Peenya, Bengaluru - 560058',
        factoryAddress:
            'Plot No. 42, Industrial Area, Phase II, Peenya, Bengaluru - 560058',
        phone: '080-28394451',
        fax: '080-28394452',
        email: 'sales@ststools.in',
        yearEstablished: 2008,
        natureOfBusiness: 'Manufacturer',
        dealerFor: null,
        mdName: 'S. T. Suresh, Managing Partner',
        contacts: [
          ContactPerson(
            name: 'R. K. Sharma',
            designation: 'Senior Sales Manager',
            phone: '9845012345',
          ),
          ContactPerson(
            name: 'V. Anand',
            designation: 'Technical Support Head',
            phone: '9845054321',
          ),
        ],
        productRange:
            'High Precision Carbide Cutting Tools, Milling Cutters & Drill Bits',
        otherFirmAssessment:
            'Audited and approved by BHEL & HAL Vendor Quality Cell',
        qcSystem: 'ISO 9001:2015 Certified, CMM Inspection Lab',
        manpowerQualified: 8,
        manpowerSkilled: 24,
        manpowerUnskilled: 12,
        machinery:
            '5-Axis CNC Tool Grinder (Walter Helitronic), Optical Profile Projector',
        annualTurnover: '4.85 Crores',
        gstNo: '29AABCS1429B1Z8',
        bankers: 'State Bank of India, Peenya Branch',
        majorCustomers:
            'Bharat Heavy Electricals Ltd, Ace Designers, Micromatic',
        evaluationMethod: 'On-site',
        purchaseMethod: 'With PO',
        recommended: true,
        preparedBy: 'M. Raghavan (Purchase In-charge)',
        approvedBy: 'Dr. K. N. Rao (Director)',
        dateOfInclusion: '15-01-2024',
        status: 'Approved',
        category: 'Spare Parts',
        createdAt: now.subtract(const Duration(days: 300)),
      ),
      Supplier(
        id: 'MSP/02',
        name: 'KK Tools Center',
        address:
            'Shop No. 14, City Market Complex, S.J.P Road, Bengaluru - 560002',
        factoryAddress:
            'Warehouse: No. 8, 3rd Cross, Lalbagh Fort Road, Bengaluru - 560004',
        phone: '080-22228890',
        fax: '080-22228891',
        email: 'contact@kktoolscenter.com',
        yearEstablished: 2012,
        natureOfBusiness: 'Dealer',
        dealerFor: 'Mitutoyo, Kennametal, Addison & Dormer Tools',
        mdName: 'Kamal Kishore Agarwal, MD',
        contacts: [
          ContactPerson(
            name: 'Kamal Kishore',
            designation: 'Managing Director',
            phone: '9880011223',
          ),
          ContactPerson(
            name: 'Manish Agarwal',
            designation: 'Accounts & Order Desk',
            phone: '9880099887',
          ),
        ],
        productRange:
            'Measuring Instruments, Vernier Calipers, Micrometers, Carbide Inserts',
        otherFirmAssessment:
            'Authorized Channel Partner certification verified',
        qcSystem:
            'Supplier Standard Calibration Certificates with NABL traceability',
        manpowerQualified: 4,
        manpowerSkilled: 10,
        manpowerUnskilled: 5,
        machinery:
            'Standard Warehousing, Temperature-Controlled Metrology Room',
        annualTurnover: '3.20 Crores',
        gstNo: '29AAFCK9821C1ZU',
        bankers: 'HDFC Bank, Richmond Road Branch',
        majorCustomers: 'Titan Engineering, L&T Precision, Bosch India',
        evaluationMethod: 'Based on Brand',
        purchaseMethod: 'With PO',
        recommended: true,
        preparedBy: 'M. Raghavan (Purchase In-charge)',
        approvedBy: 'Dr. K. N. Rao (Director)',
        dateOfInclusion: '10-03-2024',
        status: 'Approved',
        category: 'Spare Parts',
        createdAt: now.subtract(const Duration(days: 240)),
      ),
      Supplier(
        id: 'MSP/03',
        name: 'Competitive Tooling Solutions',
        address:
            'Plot 78/B, Electronic City Phase 1, Hosur Road, Bengaluru - 560100',
        factoryAddress:
            'Plot 78/B, Electronic City Phase 1, Hosur Road, Bengaluru - 560100',
        phone: '080-41123300',
        fax: '080-41123301',
        email: 'info@competitivetooling.com',
        yearEstablished: 2015,
        natureOfBusiness: 'Manufacturer',
        dealerFor: null,
        mdName: 'P. Venkatraman, CEO',
        contacts: [
          ContactPerson(
            name: 'P. Venkatraman',
            designation: 'Chief Executive Officer',
            phone: '9900144556',
          ),
          ContactPerson(
            name: 'Sunil Kumar',
            designation: 'Plant In-charge',
            phone: '9900144557',
          ),
        ],
        productRange:
            'Custom Jigs, Fixtures, Special Purpose Gauges & Press Tooling',
        otherFirmAssessment: 'Toyota Kirloskar Vendor Assessment Grade A',
        qcSystem: 'IATF 16949 / ISO 9001:2015 with in-house Carl Zeiss CMM',
        manpowerQualified: 12,
        manpowerSkilled: 35,
        manpowerUnskilled: 15,
        machinery: 'Makino CNC VMC, Wire EDM Charmilles, Surface Grinders',
        annualTurnover: '8.50 Crores',
        gstNo: '29AABCC7712E1ZQ',
        bankers: 'Canara Bank, Electronic City Branch',
        majorCustomers:
            'Toyota Auto Parts, Sansera Engineering, Motherson Sumi',
        evaluationMethod: 'On-site',
        purchaseMethod: 'With PO',
        recommended: true,
        preparedBy: 'M. Raghavan (Purchase In-charge)',
        approvedBy: 'Dr. K. N. Rao (Director)',
        dateOfInclusion: '02-06-2024',
        status: 'Approved',
        category: 'Fixed Assets',
        createdAt: now.subtract(const Duration(days: 150)),
      ),
      Supplier(
        id: 'MSP/04',
        name: 'Focus Engineering Solutions',
        address:
            'No. 120, Bommasandra Industrial Area, Anekal Taluk, Bengaluru - 560099',
        factoryAddress:
            'No. 120, Bommasandra Industrial Area, Anekal Taluk, Bengaluru - 560099',
        phone: '080-27831122',
        fax: '080-27831123',
        email: 'orders@focusengg.co.in',
        yearEstablished: 2018,
        natureOfBusiness: 'Manufacturer',
        dealerFor: null,
        mdName: 'Girish Deshpande, Proprietor',
        contacts: [
          ContactPerson(
            name: 'Girish Deshpande',
            designation: 'Proprietor',
            phone: '9740033221',
          ),
        ],
        productRange:
            'Industrial Fasteners, High Tensile Bolts, Washers, Studs & Dowel Pins',
        otherFirmAssessment: 'Supplying to Defence Ordnance Factory Medak',
        qcSystem: 'Tensile Strength Testing Rig, Salt Spray Test Chamber',
        manpowerQualified: 5,
        manpowerSkilled: 18,
        manpowerUnskilled: 20,
        machinery:
            'Cold Heading Machines, Thread Rolling Machines, Heat Treatment Furnace',
        annualTurnover: '2.90 Crores',
        gstNo: '29ABCDE3344F1Z3',
        bankers: 'Bank of Baroda, Bommasandra Branch',
        majorCustomers:
            'BEML Ltd, Tata Advanced Systems, Dynamatic Technologies',
        evaluationMethod: 'Sample',
        purchaseMethod: 'With PO',
        recommended: true,
        preparedBy: 'M. Raghavan (Purchase In-charge)',
        approvedBy: 'Dr. K. N. Rao (Director)',
        dateOfInclusion: '20-08-2024',
        status: 'Approved',
        category: 'Consumables',
        createdAt: now.subtract(const Duration(days: 80)),
      ),
      Supplier(
        id: 'MSP/05',
        name: 'H.M. Tools & Metal Mart',
        address: '15/2, Old Tharagupet, Bengaluru - 560053',
        factoryAddress:
            'Plot 31, KIADB Industrial Estate, Veerasandra, Bengaluru - 560100',
        phone: '080-26709911',
        fax: '080-26709912',
        email: 'hmtools@airtelmail.in',
        yearEstablished: 2003,
        natureOfBusiness: 'Dealer',
        dealerFor: 'Sandvik Coromant, Widia, Totem, Addison',
        mdName: 'H. M. Nooruddin, Managing Partner',
        contacts: [
          ContactPerson(
            name: 'H. M. Nooruddin',
            designation: 'Managing Partner',
            phone: '9844077889',
          ),
          ContactPerson(
            name: 'Syed Arshad',
            designation: 'Commercial Manager',
            phone: '9844077880',
          ),
        ],
        productRange:
            'High Speed Steel Tool Bits, Carbide Inserts, Coolants & Lubricants',
        otherFirmAssessment: 'Approved Vendor for HAL Overhaul Division',
        qcSystem: 'Material Test Certificates provided for every batch',
        manpowerQualified: 3,
        manpowerSkilled: 8,
        manpowerUnskilled: 6,
        machinery: 'Cut-off band saws, Automatic packing & storage racks',
        annualTurnover: '5.10 Crores',
        gstNo: '29AAACH8844D1ZK',
        bankers: 'Punjab National Bank, Gandhinagar Branch',
        majorCustomers: 'HAL, ISRO Satellite Centre, Triveni Turbine',
        evaluationMethod: 'Based on Brand',
        purchaseMethod: 'With PO',
        recommended: true,
        preparedBy: 'M. Raghavan (Purchase In-charge)',
        approvedBy: 'Dr. K. N. Rao (Director)',
        dateOfInclusion: '05-10-2024',
        status: 'Approved',
        category: 'Consumables',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }
}

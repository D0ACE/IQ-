class AwsResourcesModel {
  String? region;
  Summary? summary;
  Details? details;

  AwsResourcesModel({this.region, this.summary, this.details});

  AwsResourcesModel.fromJson(Map<String, dynamic> json) {
    region = json['region'];
    summary =
    json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    details =
    json['details'] != null ? new Details.fromJson(json['details']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['region'] = this.region;
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    if (this.details != null) {
      data['details'] = this.details!.toJson();
    }
    return data;
  }
}

class Summary {
  int? s3Buckets;
  int? ec2Instances;
  int? iamUsers;
  int? cloudFrontDistributions;

  Summary(
      {this.s3Buckets,
        this.ec2Instances,
        this.iamUsers,
        this.cloudFrontDistributions});

  Summary.fromJson(Map<String, dynamic> json) {
    s3Buckets = json['s3Buckets'];
    ec2Instances = json['ec2Instances'];
    iamUsers = json['iamUsers'];
    cloudFrontDistributions = json['cloudFrontDistributions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['s3Buckets'] = this.s3Buckets;
    data['ec2Instances'] = this.ec2Instances;
    data['iamUsers'] = this.iamUsers;
    data['cloudFrontDistributions'] = this.cloudFrontDistributions;
    return data;
  }
}

class Details {
  List<S3>? s3;
  List<Ec2>? ec2;
  List<Iam>? iam;
  List<CloudFront>? cloudFront;
  List<Billing>? billing;

  Details({this.s3, this.ec2, this.iam, this.cloudFront, this.billing});

  Details.fromJson(Map<String, dynamic> json) {
    if (json['s3'] != null) {
      s3 = <S3>[];
      json['s3'].forEach((v) {
        s3!.add(new S3.fromJson(v));
      });
    }
    if (json['ec2'] != null) {
      ec2 = <Ec2>[];
      json['ec2'].forEach((v) {
        ec2!.add(new Ec2.fromJson(v));
      });
    }
    if (json['iam'] != null) {
      iam = <Iam>[];
      json['iam'].forEach((v) {
        iam!.add(new Iam.fromJson(v));
      });
    }
    if (json['cloudFront'] != null) {
      cloudFront = <CloudFront>[];
      json['cloudFront'].forEach((v) {
        cloudFront!.add(new CloudFront.fromJson(v));
      });
    }
    if (json['billing'] != null) {
      billing = <Billing>[];
      json['billing'].forEach((v) {
        billing!.add(new Billing.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.s3 != null) {
      data['s3'] = this.s3!.map((v) => v.toJson()).toList();
    }
    if (this.ec2 != null) {
      data['ec2'] = this.ec2!.map((v) => v.toJson()).toList();
    }
    if (this.iam != null) {
      data['iam'] = this.iam!.map((v) => v.toJson()).toList();
    }
    if (this.cloudFront != null) {
      data['cloudFront'] = this.cloudFront!.map((v) => v.toJson()).toList();
    }
    if (this.billing != null) {
      data['billing'] = this.billing!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class S3 {
  String? name;
  String? createdAt;
  String? region;
  String? versioning;

  S3({this.name, this.createdAt, this.region, this.versioning});

  S3.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    createdAt = json['createdAt'];
    region = json['region'];
    versioning = json['versioning'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['createdAt'] = this.createdAt;
    data['region'] = this.region;
    data['versioning'] = this.versioning;
    return data;
  }
}

class Ec2 {
  String? instanceId;
  String? name;
  String? state;
  String? instanceType;
  String? amiId;
  String? launchTime;
  String? publicIp;
  String? privateIp;
  String? availabilityZone;
  String? vpcId;
  String? subnetId;
  String? keyName;
  List<SecurityGroups>? securityGroups;
  Tags? tags;

  Ec2(
      {this.instanceId,
        this.name,
        this.state,
        this.instanceType,
        this.amiId,
        this.launchTime,
        this.publicIp,
        this.privateIp,
        this.availabilityZone,
        this.vpcId,
        this.subnetId,
        this.keyName,
        this.securityGroups,
        this.tags});

  Ec2.fromJson(Map<String, dynamic> json) {
    instanceId = json['instanceId'];
    name = json['name'];
    state = json['state'];
    instanceType = json['instanceType'];
    amiId = json['amiId'];
    launchTime = json['launchTime'];
    publicIp = json['publicIp'];
    privateIp = json['privateIp'];
    availabilityZone = json['availabilityZone'];
    vpcId = json['vpcId'];
    subnetId = json['subnetId'];
    keyName = json['keyName'];
    if (json['securityGroups'] != null) {
      securityGroups = <SecurityGroups>[];
      json['securityGroups'].forEach((v) {
        securityGroups!.add(new SecurityGroups.fromJson(v));
      });
    }
    tags = json['tags'] != null ? new Tags.fromJson(json['tags']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['instanceId'] = this.instanceId;
    data['name'] = this.name;
    data['state'] = this.state;
    data['instanceType'] = this.instanceType;
    data['amiId'] = this.amiId;
    data['launchTime'] = this.launchTime;
    data['publicIp'] = this.publicIp;
    data['privateIp'] = this.privateIp;
    data['availabilityZone'] = this.availabilityZone;
    data['vpcId'] = this.vpcId;
    data['subnetId'] = this.subnetId;
    data['keyName'] = this.keyName;
    if (this.securityGroups != null) {
      data['securityGroups'] =
          this.securityGroups!.map((v) => v.toJson()).toList();
    }
    if (this.tags != null) {
      data['tags'] = this.tags!.toJson();
    }
    return data;
  }
}

class SecurityGroups {
  String? id;
  String? name;

  SecurityGroups({this.id, this.name});

  SecurityGroups.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

class Tags {
  String? name;
  String? backup;
  String? environment;

  Tags({this.name, this.backup, this.environment});

  Tags.fromJson(Map<String, dynamic> json) {
    name = json['Name'];
    backup = json['backup'];
    environment = json['Environment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Name'] = this.name;
    data['backup'] = this.backup;
    data['Environment'] = this.environment;
    return data;
  }
}

class Iam {
  String? userName;
  String? arn;
  String? createdAt;
  List<String>? attachedPolicies;
  String? passwordLastUsed;

  Iam(
      {this.userName,
        this.arn,
        this.createdAt,
        this.attachedPolicies,
        this.passwordLastUsed});

  Iam.fromJson(Map<String, dynamic> json) {
    userName = json['userName'];
    arn = json['arn'];
    createdAt = json['createdAt'];
    attachedPolicies = json['attachedPolicies'].cast<String>();
    passwordLastUsed = json['passwordLastUsed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userName'] = this.userName;
    data['arn'] = this.arn;
    data['createdAt'] = this.createdAt;
    data['attachedPolicies'] = this.attachedPolicies;
    data['passwordLastUsed'] = this.passwordLastUsed;
    return data;
  }
}

class CloudFront {
  String? id;
  String? domain;
  bool? enabled;
  String? priceClass;
  String? lastModified;
  List<dynamic>? aliases;
  List<Origins>? origins;

  CloudFront(
      {this.id,
        this.domain,
        this.enabled,
        this.priceClass,
        this.lastModified,
        this.aliases,
        this.origins});

  CloudFront.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    domain = json['domain'];
    enabled = json['enabled'];
    priceClass = json['priceClass'];
    lastModified = json['lastModified'];
    if (json['aliases'] != null) {
      aliases = [];
      json['aliases'].forEach((v) {
        aliases!.add(v);
      });
    }
    if (json['origins'] != null) {
      origins = <Origins>[];
      json['origins'].forEach((v) {
        origins!.add(new Origins.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['domain'] = this.domain;
    data['enabled'] = this.enabled;
    data['priceClass'] = this.priceClass;
    data['lastModified'] = this.lastModified;
    if (this.aliases != null) {
      data['aliases'] = this.aliases!.map((v) => v.toJson()).toList();
    }
    if (this.origins != null) {
      data['origins'] = this.origins!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Origins {
  String? id;
  String? domain;

  Origins({this.id, this.domain});

  Origins.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    domain = json['domain'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['domain'] = this.domain;
    return data;
  }
}

class Billing {
  String? service;
  double? amount;
  String? unit;

  Billing({this.service, this.amount, this.unit});

  Billing.fromJson(Map<String, dynamic> json) {
    service = json['service'];
    amount = json['amount'];
    unit = json['unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['service'] = this.service;
    data['amount'] = this.amount;
    data['unit'] = this.unit;
    return data;
  }
}

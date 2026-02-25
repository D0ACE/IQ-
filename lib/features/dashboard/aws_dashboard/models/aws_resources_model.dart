class AwsResourcesModel {
  String? region;
  Summary? summary;
  Details? details;

  AwsResourcesModel({this.region, this.summary, this.details});

  AwsResourcesModel.fromJson(Map<String, dynamic> json) {
    region = json['region'];
    summary =
    json['summary'] != null ? Summary.fromJson(json['summary']) : null;
    details =
    json['details'] != null ? Details.fromJson(json['details']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['region'] = region;
    if (summary != null) {
      data['summary'] = summary!.toJson();
    }
    if (details != null) {
      data['details'] = details!.toJson();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['s3Buckets'] = s3Buckets;
    data['ec2Instances'] = ec2Instances;
    data['iamUsers'] = iamUsers;
    data['cloudFrontDistributions'] = cloudFrontDistributions;
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
        s3!.add(S3.fromJson(v));
      });
    }
    if (json['ec2'] != null) {
      ec2 = <Ec2>[];
      json['ec2'].forEach((v) {
        ec2!.add(Ec2.fromJson(v));
      });
    }
    if (json['iam'] != null) {
      iam = <Iam>[];
      json['iam'].forEach((v) {
        iam!.add(Iam.fromJson(v));
      });
    }
    if (json['cloudFront'] != null) {
      cloudFront = <CloudFront>[];
      json['cloudFront'].forEach((v) {
        cloudFront!.add(CloudFront.fromJson(v));
      });
    }
    if (json['billing'] != null) {
      billing = <Billing>[];
      json['billing'].forEach((v) {
        billing!.add(Billing.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (s3 != null) {
      data['s3'] = s3!.map((v) => v.toJson()).toList();
    }
    if (ec2 != null) {
      data['ec2'] = ec2!.map((v) => v.toJson()).toList();
    }
    if (iam != null) {
      data['iam'] = iam!.map((v) => v.toJson()).toList();
    }
    if (cloudFront != null) {
      data['cloudFront'] = cloudFront!.map((v) => v.toJson()).toList();
    }
    if (billing != null) {
      data['billing'] = billing!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['createdAt'] = createdAt;
    data['region'] = region;
    data['versioning'] = versioning;
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
        securityGroups!.add(SecurityGroups.fromJson(v));
      });
    }
    tags = json['tags'] != null ? Tags.fromJson(json['tags']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['instanceId'] = instanceId;
    data['name'] = name;
    data['state'] = state;
    data['instanceType'] = instanceType;
    data['amiId'] = amiId;
    data['launchTime'] = launchTime;
    data['publicIp'] = publicIp;
    data['privateIp'] = privateIp;
    data['availabilityZone'] = availabilityZone;
    data['vpcId'] = vpcId;
    data['subnetId'] = subnetId;
    data['keyName'] = keyName;
    if (securityGroups != null) {
      data['securityGroups'] =
          securityGroups!.map((v) => v.toJson()).toList();
    }
    if (tags != null) {
      data['tags'] = tags!.toJson();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Name'] = name;
    data['backup'] = backup;
    data['Environment'] = environment;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userName'] = userName;
    data['arn'] = arn;
    data['createdAt'] = createdAt;
    data['attachedPolicies'] = attachedPolicies;
    data['passwordLastUsed'] = passwordLastUsed;
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
        origins!.add(Origins.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['domain'] = domain;
    data['enabled'] = enabled;
    data['priceClass'] = priceClass;
    data['lastModified'] = lastModified;
    if (aliases != null) {
      data['aliases'] = aliases!.map((v) => v.toJson()).toList();
    }
    if (origins != null) {
      data['origins'] = origins!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['domain'] = domain;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['service'] = service;
    data['amount'] = amount;
    data['unit'] = unit;
    return data;
  }
}

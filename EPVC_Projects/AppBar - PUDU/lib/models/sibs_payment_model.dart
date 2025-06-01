class SibsPaymentRequest {
  final Merchant merchant;
  final Transaction transaction;
  final Customer? customer;
  final RecurringTransaction? recurringTransaction;
  final Tokenisation? tokenisation;

  SibsPaymentRequest({
    required this.merchant,
    required this.transaction,
    this.customer,
    this.recurringTransaction,
    this.tokenisation,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'merchant': merchant.toJson(),
      'transaction': transaction.toJson(),
    };

    if (customer != null) {
      data['customer'] = customer!.toJson();
    }

    if (recurringTransaction != null) {
      data['recurringTransaction'] = recurringTransaction!.toJson();
    }

    if (tokenisation != null) {
      data['tokenisation'] = tokenisation!.toJson();
    }

    return data;
  }
}

class Merchant {
  final String terminalId;
  final String channel;
  final String merchantTransactionId;

  Merchant({
    required this.terminalId,
    required this.channel,
    required this.merchantTransactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'terminalId': terminalId,
      'channel': channel,
      'merchantTransactionId': merchantTransactionId,
    };
  }
}

class Transaction {
  final String transactionTimestamp;
  final String description;
  final bool moto;
  final String paymentType;
  final Amount amount;
  final List<String> paymentMethod;
  final PaymentReference? paymentReference;

  Transaction({
    required this.transactionTimestamp,
    required this.description,
    required this.moto,
    required this.paymentType,
    required this.amount,
    required this.paymentMethod,
    this.paymentReference,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'transactionTimestamp': transactionTimestamp,
      'description': description,
      'moto': moto,
      'paymentType': paymentType,
      'amount': amount.toJson(),
      'paymentMethod': paymentMethod,
    };

    if (paymentReference != null) {
      data['paymentReference'] = paymentReference!.toJson();
    }

    return data;
  }
}

class Amount {
  final double value;
  final String currency;

  Amount({
    required this.value,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'currency': currency,
    };
  }
}

class PaymentReference {
  final String initialDatetime;
  final String finalDatetime;
  final Amount maxAmount;
  final Amount minAmount;
  final String entity;

  PaymentReference({
    required this.initialDatetime,
    required this.finalDatetime,
    required this.maxAmount,
    required this.minAmount,
    required this.entity,
  });

  Map<String, dynamic> toJson() {
    return {
      'initialDatetime': initialDatetime,
      'finalDatetime': finalDatetime,
      'maxAmount': maxAmount.toJson(),
      'minAmount': minAmount.toJson(),
      'entity': entity,
    };
  }
}

class Customer {
  final CustomerInfo customerInfo;

  Customer({
    required this.customerInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerInfo': customerInfo.toJson(),
    };
  }
}

class CustomerInfo {
  final String customerEmail;
  final Address shippingAddress;
  final Address billingAddress;

  CustomerInfo({
    required this.customerEmail,
    required this.shippingAddress,
    required this.billingAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress.toJson(),
      'billingAddress': billingAddress.toJson(),
    };
  }
}

class Address {
  final String street1;
  final String? street2;
  final String city;
  final String postcode;
  final String country;

  Address({
    required this.street1,
    this.street2,
    required this.city,
    required this.postcode,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'street1': street1,
      'city': city,
      'postcode': postcode,
      'country': country,
    };

    if (street2 != null && street2!.isNotEmpty) {
      data['street2'] = street2;
    }

    return data;
  }
}

class RecurringTransaction {
  final String validityDate;
  final String amountQualifier;
  final String description;

  RecurringTransaction({
    required this.validityDate,
    required this.amountQualifier,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'validityDate': validityDate,
      'amountQualifier': amountQualifier,
      'description': description,
    };
  }
}

class Tokenisation {
  final TokenisationRequest tokenisationRequest;

  Tokenisation({
    required this.tokenisationRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokenisationRequest': tokenisationRequest.toJson(),
    };
  }
}

class TokenisationRequest {
  final bool tokeniseCard;

  TokenisationRequest({
    required this.tokeniseCard,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokeniseCard': tokeniseCard,
    };
  }
}

class SibsPaymentResponse {
  final Amount? amount;
  final Merchant merchant;
  final String transactionID;
  final String transactionSignature;
  final String formContext;
  final String expiry;
  final List<dynamic> tokenList;
  final List<String> paymentMethodList;
  final Execution execution;
  final ReturnStatus returnStatus;

  SibsPaymentResponse({
    this.amount,
    required this.merchant,
    required this.transactionID,
    required this.transactionSignature,
    required this.formContext,
    required this.expiry,
    required this.tokenList,
    required this.paymentMethodList,
    required this.execution,
    required this.returnStatus,
  });

  factory SibsPaymentResponse.fromJson(Map<String, dynamic> json) {
    return SibsPaymentResponse(
      amount: json['amount'] != null ? Amount(
        value: json['amount']['value'] is int
            ? json['amount']['value'].toDouble()
            : double.parse(json['amount']['value'].toString()),
        currency: json['amount']['currency'],
      ) : null,
      merchant: Merchant(
        terminalId: json['merchant']['terminalId'].toString(),
        channel: 'web',
        merchantTransactionId: json['merchant']['merchantTransactionId'],
      ),
      transactionID: json['transactionID'],
      transactionSignature: json['transactionSignature'],
      formContext: json['formContext'],
      expiry: json['expiry'],
      tokenList: json['tokenList'] ?? [],
      paymentMethodList: List<String>.from(json['paymentMethodList'] ?? []),
      execution: Execution.fromJson(json['execution']),
      returnStatus: ReturnStatus.fromJson(json['returnStatus']),
    );
  }
}

class MbwayRequest {
  final String customerPhone;

  MbwayRequest({required this.customerPhone});

  Map<String, dynamic> toJson() {
    return {
      'customerPhone': customerPhone,
    };
  }
}

class MbwayResponse {
  final String transactionID;
  final Execution execution;
  final String paymentStatus;
  final ReturnStatus returnStatus;

  MbwayResponse({
    required this.transactionID,
    required this.execution,
    required this.paymentStatus,
    required this.returnStatus,
  });

  factory MbwayResponse.fromJson(Map<String, dynamic> json) {
    return MbwayResponse(
      transactionID: json['transactionID'],
      execution: Execution.fromJson(json['execution']),
      paymentStatus: json['paymentStatus'],
      returnStatus: ReturnStatus.fromJson(json['returnStatus']),
    );
  }
}

class Execution {
  final String startTime;
  final String endTime;

  Execution({
    required this.startTime,
    required this.endTime,
  });

  factory Execution.fromJson(Map<String, dynamic> json) {
    return Execution(
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}

class ReturnStatus {
  final String statusCode;
  final String statusMsg;
  final String statusDescription;

  ReturnStatus({
    required this.statusCode,
    required this.statusMsg,
    required this.statusDescription,
  });

  factory ReturnStatus.fromJson(Map<String, dynamic> json) {
    return ReturnStatus(
      statusCode: json['statusCode'],
      statusMsg: json['statusMsg'],
      statusDescription: json['statusDescription'],
    );
  }
}

class PaymentStatusResponse {
  final Merchant merchant;
  final String transactionID;
  final Amount amount;
  final String paymentType;
  final String paymentStatus;
  final String paymentMethod;
  final Execution execution;
  final ReturnStatus returnStatus;

  PaymentStatusResponse({
    required this.merchant,
    required this.transactionID,
    required this.amount,
    required this.paymentType,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.execution,
    required this.returnStatus,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      merchant: Merchant(
        terminalId: json['merchant']['terminalId'].toString(),
        channel: 'web',
        merchantTransactionId: json['merchant']['merchantTransactionId'],
      ),
      transactionID: json['transactionID'],
      amount: Amount(
        value: json['amount']['value'] is int
            ? json['amount']['value'].toDouble()
            : double.parse(json['amount']['value'].toString()),
        currency: json['amount']['currency'],
      ),
      paymentType: json['paymentType'],
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      execution: Execution.fromJson(json['execution']),
      returnStatus: ReturnStatus.fromJson(json['returnStatus']),
    );
  }
} 
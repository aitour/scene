# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: rpc.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
from google.protobuf import descriptor_pb2
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='rpc.proto',
  package='serverpb',
  syntax='proto3',
  serialized_pb=_b('\n\trpc.proto\x12\x08serverpb\"<\n\x0b\x41uthRequest\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x10\n\x08password\x18\x02 \x01(\t\x12\r\n\x05token\x18\x03 \x01(\t\"A\n\x0c\x41uthResponse\x12\x15\n\rrequire_login\x18\x01 \x01(\x08\x12\r\n\x05token\x18\x02 \x01(\t\x12\x0b\n\x03msg\x18\x03 \x01(\t\"2\n\x0bGeoPosition\x12\x10\n\x08latitude\x18\x01 \x01(\x01\x12\x11\n\tlongitude\x18\x02 \x01(\x01\"\x93\x01\n\x08SignSpot\x12\n\n\x02id\x18\x01 \x01(\x04\x12\x0c\n\x04name\x18\x02 \x01(\t\x12-\n\x04type\x18\x03 \x01(\x0e\x32\x1f.serverpb.SignSpot.SignSpotType\x12\"\n\x03geo\x18\x04 \x01(\x0b\x32\x15.serverpb.GeoPosition\"\x1a\n\x0cSignSpotType\x12\n\n\x06Museum\x10\x00\"\x8d\x02\n\x13PhotoPredictRequest\x12\x35\n\x04type\x18\x01 \x01(\x0e\x32\'.serverpb.PhotoPredictRequest.PhotoType\x12\x0c\n\x04\x64\x61ta\x18\x02 \x01(\x0c\x12\x16\n\x0e\x62\x61se64_encoded\x18\x03 \x01(\x08\x12\"\n\x03geo\x18\x04 \x01(\x0b\x32\x15.serverpb.GeoPosition\x12\x14\n\x0c\x61\x63quire_text\x18\x05 \x01(\x08\x12\x15\n\racquire_audio\x18\x06 \x01(\x08\x12\x15\n\racquire_video\x18\x07 \x01(\x08\x12\x12\n\nmax_limits\x18\x08 \x01(\x05\"\x1d\n\tPhotoType\x12\x07\n\x03PNG\x10\x00\x12\x07\n\x03JPG\x10\x01\"\x9f\x01\n\x14PhotoPredictResponse\x12\x36\n\x07results\x18\x01 \x03(\x0b\x32%.serverpb.PhotoPredictResponse.Result\x1aO\n\x06Result\x12\x0c\n\x04text\x18\x01 \x01(\t\x12\x11\n\timage_url\x18\x02 \x01(\t\x12\x11\n\taudio_url\x18\x03 \x01(\t\x12\x11\n\tvideo_url\x18\x04 \x01(\t2G\n\x04\x41uth\x12?\n\x0c\x41uthenticate\x12\x15.serverpb.AuthRequest\x1a\x16.serverpb.AuthResponse\"\x00\x32Z\n\x07Predict\x12O\n\x0cPredictPhoto\x12\x1d.serverpb.PhotoPredictRequest\x1a\x1e.serverpb.PhotoPredictResponse\"\x00\x42&\n\x0e\x63om.aitour.rpcB\tAuthProtoP\x01\xa2\x02\x06\x61itourb\x06proto3')
)



_SIGNSPOT_SIGNSPOTTYPE = _descriptor.EnumDescriptor(
  name='SignSpotType',
  full_name='serverpb.SignSpot.SignSpotType',
  filename=None,
  file=DESCRIPTOR,
  values=[
    _descriptor.EnumValueDescriptor(
      name='Museum', index=0, number=0,
      options=None,
      type=None),
  ],
  containing_type=None,
  options=None,
  serialized_start=326,
  serialized_end=352,
)
_sym_db.RegisterEnumDescriptor(_SIGNSPOT_SIGNSPOTTYPE)

_PHOTOPREDICTREQUEST_PHOTOTYPE = _descriptor.EnumDescriptor(
  name='PhotoType',
  full_name='serverpb.PhotoPredictRequest.PhotoType',
  filename=None,
  file=DESCRIPTOR,
  values=[
    _descriptor.EnumValueDescriptor(
      name='PNG', index=0, number=0,
      options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='JPG', index=1, number=1,
      options=None,
      type=None),
  ],
  containing_type=None,
  options=None,
  serialized_start=595,
  serialized_end=624,
)
_sym_db.RegisterEnumDescriptor(_PHOTOPREDICTREQUEST_PHOTOTYPE)


_AUTHREQUEST = _descriptor.Descriptor(
  name='AuthRequest',
  full_name='serverpb.AuthRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='name', full_name='serverpb.AuthRequest.name', index=0,
      number=1, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='password', full_name='serverpb.AuthRequest.password', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='token', full_name='serverpb.AuthRequest.token', index=2,
      number=3, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=23,
  serialized_end=83,
)


_AUTHRESPONSE = _descriptor.Descriptor(
  name='AuthResponse',
  full_name='serverpb.AuthResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='require_login', full_name='serverpb.AuthResponse.require_login', index=0,
      number=1, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='token', full_name='serverpb.AuthResponse.token', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='msg', full_name='serverpb.AuthResponse.msg', index=2,
      number=3, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=85,
  serialized_end=150,
)


_GEOPOSITION = _descriptor.Descriptor(
  name='GeoPosition',
  full_name='serverpb.GeoPosition',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='latitude', full_name='serverpb.GeoPosition.latitude', index=0,
      number=1, type=1, cpp_type=5, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='longitude', full_name='serverpb.GeoPosition.longitude', index=1,
      number=2, type=1, cpp_type=5, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=152,
  serialized_end=202,
)


_SIGNSPOT = _descriptor.Descriptor(
  name='SignSpot',
  full_name='serverpb.SignSpot',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='id', full_name='serverpb.SignSpot.id', index=0,
      number=1, type=4, cpp_type=4, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='name', full_name='serverpb.SignSpot.name', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='type', full_name='serverpb.SignSpot.type', index=2,
      number=3, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='geo', full_name='serverpb.SignSpot.geo', index=3,
      number=4, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
    _SIGNSPOT_SIGNSPOTTYPE,
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=205,
  serialized_end=352,
)


_PHOTOPREDICTREQUEST = _descriptor.Descriptor(
  name='PhotoPredictRequest',
  full_name='serverpb.PhotoPredictRequest',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='type', full_name='serverpb.PhotoPredictRequest.type', index=0,
      number=1, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='data', full_name='serverpb.PhotoPredictRequest.data', index=1,
      number=2, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='base64_encoded', full_name='serverpb.PhotoPredictRequest.base64_encoded', index=2,
      number=3, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='geo', full_name='serverpb.PhotoPredictRequest.geo', index=3,
      number=4, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='acquire_text', full_name='serverpb.PhotoPredictRequest.acquire_text', index=4,
      number=5, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='acquire_audio', full_name='serverpb.PhotoPredictRequest.acquire_audio', index=5,
      number=6, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='acquire_video', full_name='serverpb.PhotoPredictRequest.acquire_video', index=6,
      number=7, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='max_limits', full_name='serverpb.PhotoPredictRequest.max_limits', index=7,
      number=8, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
    _PHOTOPREDICTREQUEST_PHOTOTYPE,
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=355,
  serialized_end=624,
)


_PHOTOPREDICTRESPONSE_RESULT = _descriptor.Descriptor(
  name='Result',
  full_name='serverpb.PhotoPredictResponse.Result',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='text', full_name='serverpb.PhotoPredictResponse.Result.text', index=0,
      number=1, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='image_url', full_name='serverpb.PhotoPredictResponse.Result.image_url', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='audio_url', full_name='serverpb.PhotoPredictResponse.Result.audio_url', index=2,
      number=3, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    _descriptor.FieldDescriptor(
      name='video_url', full_name='serverpb.PhotoPredictResponse.Result.video_url', index=3,
      number=4, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=707,
  serialized_end=786,
)

_PHOTOPREDICTRESPONSE = _descriptor.Descriptor(
  name='PhotoPredictResponse',
  full_name='serverpb.PhotoPredictResponse',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='results', full_name='serverpb.PhotoPredictResponse.results', index=0,
      number=1, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[_PHOTOPREDICTRESPONSE_RESULT, ],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=627,
  serialized_end=786,
)

_SIGNSPOT.fields_by_name['type'].enum_type = _SIGNSPOT_SIGNSPOTTYPE
_SIGNSPOT.fields_by_name['geo'].message_type = _GEOPOSITION
_SIGNSPOT_SIGNSPOTTYPE.containing_type = _SIGNSPOT
_PHOTOPREDICTREQUEST.fields_by_name['type'].enum_type = _PHOTOPREDICTREQUEST_PHOTOTYPE
_PHOTOPREDICTREQUEST.fields_by_name['geo'].message_type = _GEOPOSITION
_PHOTOPREDICTREQUEST_PHOTOTYPE.containing_type = _PHOTOPREDICTREQUEST
_PHOTOPREDICTRESPONSE_RESULT.containing_type = _PHOTOPREDICTRESPONSE
_PHOTOPREDICTRESPONSE.fields_by_name['results'].message_type = _PHOTOPREDICTRESPONSE_RESULT
DESCRIPTOR.message_types_by_name['AuthRequest'] = _AUTHREQUEST
DESCRIPTOR.message_types_by_name['AuthResponse'] = _AUTHRESPONSE
DESCRIPTOR.message_types_by_name['GeoPosition'] = _GEOPOSITION
DESCRIPTOR.message_types_by_name['SignSpot'] = _SIGNSPOT
DESCRIPTOR.message_types_by_name['PhotoPredictRequest'] = _PHOTOPREDICTREQUEST
DESCRIPTOR.message_types_by_name['PhotoPredictResponse'] = _PHOTOPREDICTRESPONSE
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

AuthRequest = _reflection.GeneratedProtocolMessageType('AuthRequest', (_message.Message,), dict(
  DESCRIPTOR = _AUTHREQUEST,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.AuthRequest)
  ))
_sym_db.RegisterMessage(AuthRequest)

AuthResponse = _reflection.GeneratedProtocolMessageType('AuthResponse', (_message.Message,), dict(
  DESCRIPTOR = _AUTHRESPONSE,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.AuthResponse)
  ))
_sym_db.RegisterMessage(AuthResponse)

GeoPosition = _reflection.GeneratedProtocolMessageType('GeoPosition', (_message.Message,), dict(
  DESCRIPTOR = _GEOPOSITION,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.GeoPosition)
  ))
_sym_db.RegisterMessage(GeoPosition)

SignSpot = _reflection.GeneratedProtocolMessageType('SignSpot', (_message.Message,), dict(
  DESCRIPTOR = _SIGNSPOT,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.SignSpot)
  ))
_sym_db.RegisterMessage(SignSpot)

PhotoPredictRequest = _reflection.GeneratedProtocolMessageType('PhotoPredictRequest', (_message.Message,), dict(
  DESCRIPTOR = _PHOTOPREDICTREQUEST,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.PhotoPredictRequest)
  ))
_sym_db.RegisterMessage(PhotoPredictRequest)

PhotoPredictResponse = _reflection.GeneratedProtocolMessageType('PhotoPredictResponse', (_message.Message,), dict(

  Result = _reflection.GeneratedProtocolMessageType('Result', (_message.Message,), dict(
    DESCRIPTOR = _PHOTOPREDICTRESPONSE_RESULT,
    __module__ = 'rpc_pb2'
    # @@protoc_insertion_point(class_scope:serverpb.PhotoPredictResponse.Result)
    ))
  ,
  DESCRIPTOR = _PHOTOPREDICTRESPONSE,
  __module__ = 'rpc_pb2'
  # @@protoc_insertion_point(class_scope:serverpb.PhotoPredictResponse)
  ))
_sym_db.RegisterMessage(PhotoPredictResponse)
_sym_db.RegisterMessage(PhotoPredictResponse.Result)


DESCRIPTOR.has_options = True
DESCRIPTOR._options = _descriptor._ParseOptions(descriptor_pb2.FileOptions(), _b('\n\016com.aitour.rpcB\tAuthProtoP\001\242\002\006aitour'))

_AUTH = _descriptor.ServiceDescriptor(
  name='Auth',
  full_name='serverpb.Auth',
  file=DESCRIPTOR,
  index=0,
  options=None,
  serialized_start=788,
  serialized_end=859,
  methods=[
  _descriptor.MethodDescriptor(
    name='Authenticate',
    full_name='serverpb.Auth.Authenticate',
    index=0,
    containing_service=None,
    input_type=_AUTHREQUEST,
    output_type=_AUTHRESPONSE,
    options=None,
  ),
])
_sym_db.RegisterServiceDescriptor(_AUTH)

DESCRIPTOR.services_by_name['Auth'] = _AUTH


_PREDICT = _descriptor.ServiceDescriptor(
  name='Predict',
  full_name='serverpb.Predict',
  file=DESCRIPTOR,
  index=1,
  options=None,
  serialized_start=861,
  serialized_end=951,
  methods=[
  _descriptor.MethodDescriptor(
    name='PredictPhoto',
    full_name='serverpb.Predict.PredictPhoto',
    index=0,
    containing_service=None,
    input_type=_PHOTOPREDICTREQUEST,
    output_type=_PHOTOPREDICTRESPONSE,
    options=None,
  ),
])
_sym_db.RegisterServiceDescriptor(_PREDICT)

DESCRIPTOR.services_by_name['Predict'] = _PREDICT

try:
  # THESE ELEMENTS WILL BE DEPRECATED.
  # Please use the generated *_pb2_grpc.py files instead.
  import grpc
  from grpc.beta import implementations as beta_implementations
  from grpc.beta import interfaces as beta_interfaces
  from grpc.framework.common import cardinality
  from grpc.framework.interfaces.face import utilities as face_utilities


  class AuthStub(object):
    # missing associated documentation comment in .proto file
    pass

    def __init__(self, channel):
      """Constructor.

      Args:
        channel: A grpc.Channel.
      """
      self.Authenticate = channel.unary_unary(
          '/serverpb.Auth/Authenticate',
          request_serializer=AuthRequest.SerializeToString,
          response_deserializer=AuthResponse.FromString,
          )


  class AuthServicer(object):
    # missing associated documentation comment in .proto file
    pass

    def Authenticate(self, request, context):
      # missing associated documentation comment in .proto file
      pass
      context.set_code(grpc.StatusCode.UNIMPLEMENTED)
      context.set_details('Method not implemented!')
      raise NotImplementedError('Method not implemented!')


  def add_AuthServicer_to_server(servicer, server):
    rpc_method_handlers = {
        'Authenticate': grpc.unary_unary_rpc_method_handler(
            servicer.Authenticate,
            request_deserializer=AuthRequest.FromString,
            response_serializer=AuthResponse.SerializeToString,
        ),
    }
    generic_handler = grpc.method_handlers_generic_handler(
        'serverpb.Auth', rpc_method_handlers)
    server.add_generic_rpc_handlers((generic_handler,))


  class PredictStub(object):
    # missing associated documentation comment in .proto file
    pass

    def __init__(self, channel):
      """Constructor.

      Args:
        channel: A grpc.Channel.
      """
      self.PredictPhoto = channel.unary_unary(
          '/serverpb.Predict/PredictPhoto',
          request_serializer=PhotoPredictRequest.SerializeToString,
          response_deserializer=PhotoPredictResponse.FromString,
          )


  class PredictServicer(object):
    # missing associated documentation comment in .proto file
    pass

    def PredictPhoto(self, request, context):
      # missing associated documentation comment in .proto file
      pass
      context.set_code(grpc.StatusCode.UNIMPLEMENTED)
      context.set_details('Method not implemented!')
      raise NotImplementedError('Method not implemented!')


  def add_PredictServicer_to_server(servicer, server):
    rpc_method_handlers = {
        'PredictPhoto': grpc.unary_unary_rpc_method_handler(
            servicer.PredictPhoto,
            request_deserializer=PhotoPredictRequest.FromString,
            response_serializer=PhotoPredictResponse.SerializeToString,
        ),
    }
    generic_handler = grpc.method_handlers_generic_handler(
        'serverpb.Predict', rpc_method_handlers)
    server.add_generic_rpc_handlers((generic_handler,))


  class BetaAuthServicer(object):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This class was generated
    only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0."""
    # missing associated documentation comment in .proto file
    pass
    def Authenticate(self, request, context):
      # missing associated documentation comment in .proto file
      pass
      context.code(beta_interfaces.StatusCode.UNIMPLEMENTED)


  class BetaAuthStub(object):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This class was generated
    only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0."""
    # missing associated documentation comment in .proto file
    pass
    def Authenticate(self, request, timeout, metadata=None, with_call=False, protocol_options=None):
      # missing associated documentation comment in .proto file
      pass
      raise NotImplementedError()
    Authenticate.future = None


  def beta_create_Auth_server(servicer, pool=None, pool_size=None, default_timeout=None, maximum_timeout=None):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This function was
    generated only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0"""
    request_deserializers = {
      ('serverpb.Auth', 'Authenticate'): AuthRequest.FromString,
    }
    response_serializers = {
      ('serverpb.Auth', 'Authenticate'): AuthResponse.SerializeToString,
    }
    method_implementations = {
      ('serverpb.Auth', 'Authenticate'): face_utilities.unary_unary_inline(servicer.Authenticate),
    }
    server_options = beta_implementations.server_options(request_deserializers=request_deserializers, response_serializers=response_serializers, thread_pool=pool, thread_pool_size=pool_size, default_timeout=default_timeout, maximum_timeout=maximum_timeout)
    return beta_implementations.server(method_implementations, options=server_options)


  def beta_create_Auth_stub(channel, host=None, metadata_transformer=None, pool=None, pool_size=None):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This function was
    generated only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0"""
    request_serializers = {
      ('serverpb.Auth', 'Authenticate'): AuthRequest.SerializeToString,
    }
    response_deserializers = {
      ('serverpb.Auth', 'Authenticate'): AuthResponse.FromString,
    }
    cardinalities = {
      'Authenticate': cardinality.Cardinality.UNARY_UNARY,
    }
    stub_options = beta_implementations.stub_options(host=host, metadata_transformer=metadata_transformer, request_serializers=request_serializers, response_deserializers=response_deserializers, thread_pool=pool, thread_pool_size=pool_size)
    return beta_implementations.dynamic_stub(channel, 'serverpb.Auth', cardinalities, options=stub_options)


  class BetaPredictServicer(object):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This class was generated
    only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0."""
    # missing associated documentation comment in .proto file
    pass
    def PredictPhoto(self, request, context):
      # missing associated documentation comment in .proto file
      pass
      context.code(beta_interfaces.StatusCode.UNIMPLEMENTED)


  class BetaPredictStub(object):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This class was generated
    only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0."""
    # missing associated documentation comment in .proto file
    pass
    def PredictPhoto(self, request, timeout, metadata=None, with_call=False, protocol_options=None):
      # missing associated documentation comment in .proto file
      pass
      raise NotImplementedError()
    PredictPhoto.future = None


  def beta_create_Predict_server(servicer, pool=None, pool_size=None, default_timeout=None, maximum_timeout=None):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This function was
    generated only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0"""
    request_deserializers = {
      ('serverpb.Predict', 'PredictPhoto'): PhotoPredictRequest.FromString,
    }
    response_serializers = {
      ('serverpb.Predict', 'PredictPhoto'): PhotoPredictResponse.SerializeToString,
    }
    method_implementations = {
      ('serverpb.Predict', 'PredictPhoto'): face_utilities.unary_unary_inline(servicer.PredictPhoto),
    }
    server_options = beta_implementations.server_options(request_deserializers=request_deserializers, response_serializers=response_serializers, thread_pool=pool, thread_pool_size=pool_size, default_timeout=default_timeout, maximum_timeout=maximum_timeout)
    return beta_implementations.server(method_implementations, options=server_options)


  def beta_create_Predict_stub(channel, host=None, metadata_transformer=None, pool=None, pool_size=None):
    """The Beta API is deprecated for 0.15.0 and later.

    It is recommended to use the GA API (classes and functions in this
    file not marked beta) for all further purposes. This function was
    generated only to ease transition from grpcio<0.15.0 to grpcio>=0.15.0"""
    request_serializers = {
      ('serverpb.Predict', 'PredictPhoto'): PhotoPredictRequest.SerializeToString,
    }
    response_deserializers = {
      ('serverpb.Predict', 'PredictPhoto'): PhotoPredictResponse.FromString,
    }
    cardinalities = {
      'PredictPhoto': cardinality.Cardinality.UNARY_UNARY,
    }
    stub_options = beta_implementations.stub_options(host=host, metadata_transformer=metadata_transformer, request_serializers=request_serializers, response_deserializers=response_deserializers, thread_pool=pool, thread_pool_size=pool_size)
    return beta_implementations.dynamic_stub(channel, 'serverpb.Predict', cardinalities, options=stub_options)
except ImportError:
  pass
# @@protoc_insertion_point(module_scope)

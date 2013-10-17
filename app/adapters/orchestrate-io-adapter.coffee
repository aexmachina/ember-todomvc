DS.OrchestrateIOAdapter = DS.RESTAdapter.extend(
    Ember.Evented,

  apiKey: null
  host: 'http://api.orchestrate.io'
  namespace: 'v0'

  defaultSerializer: '_oio'

  ##
  # @todo sinceToken is ignored
  findAll: (store, type, sinceToken)->
    @findQuery store, type, '*'
  findMany: (store, type, ids)->
    if ids.length == 0 then return Ember.RSVP.resolve []
    params = new Array(ids.length)
    params.push "_id:#{id}" for id in ids
    @_query store, type, params
  findQuery: (store, type, query)->
    params = []
    if typeof query == 'string'
      params = [query]
    else
      for property, value of query
        if !value
          throw 'Searching for empty properties is currently not supported'
        else if typeof value.test == 'function'
          throw 'Regular expressions are currently not supported '
        else
          params.push "#{property}:#{value}"
    @_query store, type, params
  _query: (store, type, params)->
    @ajax @buildURL(type.typeKey), 'GET', data: query: params.join ' '
  ##
  # Copied from RESTAdapter because we need to use "PUT" method rather than "POST"
  createRecord: (store, type, record)->
    data = {}
    serializer = store.serializerFor(type.typeKey)
    serializer.serializeIntoHash data, type, record, includeId: true
    @ajax @buildURL(type.typeKey, record.id), "PUT", data: data
  ajaxOptions: (url, type, options)->
    unless options then options = {}
    options.username = @apiKey
    @_super url, type, options
  generateIdForRecord: (store, type, record)->
    Math.random().toString(32).substr(2, 7)
)

DS.OrchestrateIOSerializer = DS.RESTSerializer.extend
  extractSingle: (store, primaryType, payload, recordId, requestType)->
    results = payload
    payloadForSuper = {}
    payloadForSuper[primaryType.typeKey] = results.value[primaryType]
    @_super store, primaryType, payloadForSuper, recordId, requestType
  extractArray: (store, primaryType, payload)->
    results = []
    for result in payload.results
      results.push result.value[primaryType.typeKey]
    payloadForSuper = {}
    payloadForSuper[primaryType.typeKey] = results
    @_super store, primaryType, payloadForSuper

Ember.onLoad 'Ember.Application', (Application)->
  Application.initializer
    name: "orchestrateIOAdapter"
    initialize: (container, application)->
      application.register 'serializer:_oio', DS.OrchestrateIOSerializer
      application.register 'adapter:_oio', DS.OrchestrateIOAdapter

// aggregates data and archives locations if they are no longer valid
Parse.Cloud.afterSave('pingResponse', function (request) {
  // thresholds for adding info and archiving hotspot
  var infoAddThreshold = 2;
  var archiveHotspotThreshold = 2;

  // get values from just saved object
  var responseId = request.object.id;
  var hotspotId = request.object.get('hotspotId');
  var question = request.object.get('question');
  var questionResponse = request.object.get('response');
  var timestamp = request.object.get('timestamp');

  var getHotspotData = new Parse.Query('hotspot');
  getHotspotData.equalTo('objectId', hotspotId);
  getHotspotData.first({
    success: function (hotspotObject) {
      var lastUpdateTimestamp = hotspotObject.get('timestampLastUpdate');

      var responseForHotspot = new Parse.Query('pingResponse');
      responseForHotspot.equalTo('hotspotId', hotspotId);
      responseForHotspot.equalTo('question', question);
      responseForHotspot.greaterThanOrEqualTo('timestamp', lastUpdateTimestamp);
      responseForHotspot.find({
        success: function (hotspotResponses) {
          var similarResponseCount = 0;

          for (var i = 0; i < hotspotResponses.length; i++) {
            var currentResponse = hotspotResponses[i].get('response');
            var currentId = hotspotResponses[i].id;

            if (currentId != responseId &&
                currentResponse == questionResponse) {
              similarResponseCount++;
            }
          }

          if (similarResponseCount >= infoAddThreshold) {
            var newUpdateTimestamp = Math.round(Date.now() / 1000);
            var newInfo = hotspotObject.get('info');
            newInfo.question = questionResponse;
            hotspotObject.set('timestampLastUpdate', newUpdateTimestamp);
            hotspotObject.set('info', newInfo);
            hotspotObject.save();
          }
        },
        error: function (error) {
          /*jshint ignore:start*/
          console.log(error);
          /*jshint ignore:end*/
        }
      });
    },
    error: function (error) {
      /*jshint ignore:start*/
      console.log(error);
      /*jshint ignore:end*/
    }
  });
});

// Get n closest hotspots ranked by distance and preference
// request = {latitude: Int, longitude: Int, vendorId: Str, count: Int}
Parse.Cloud.define('retrieveLocationsForTracking', function(request, response) {
  var currentLocation = {
    'latitude': request.params.latitude,
    'longitude': request.params.longitude
  };
  var distanceToHotspots = [];

  var preferenceQuery = new Parse.Query('user');
  preferenceQuery.equalTo('vendorId', request.params.vendorId);
  preferenceQuery.find({
    success: function (preferences) {
      var userPreferences = {
          'firstPreference': 0,
          'secondPreference': 0,
          'thirdPreference': 0,
          'fourthPreference': 0
        };

      if (preferences.length > 0) {
        var firstPreference = preferences[0].get('firstPreference');
        var secondPreference = preferences[0].get('secondPreference');
        var thirdPreference = preferences[0].get('thirdPreference');
        var fourthPreference = preferences[0].get('fourthPreference');

        userPreferences.firstPreference = firstPreference;
        userPreferences.secondPreference = secondPreference;
        userPreferences.thirdPreference = thirdPreference;
        userPreferences.fourthPreference = fourthPreference;
      }

      var preferenceDict = {
        'food': getRankForCategory('food', userPreferences),
        'queue': getRankForCategory('queue', userPreferences),
        'space': getRankForCategory('space', userPreferences),
        'surprising': getRankForCategory('surprising', userPreferences)
      };

      var prevRespondedQuery = new Parse.Query('pingResponse');
      prevRespondedQuery.equalTo('vendorId', request.params.vendorId);
      prevRespondedQuery.find({
        success: function (prevNotifications) {
          var prevNotificationLen = prevNotifications.length;

          // return locations sorted by distance and ranking for user
          var locationQuery = new Parse.Query('hotspot');
          locationQuery.find({
            success: function (locations) {
              for (var i = 0; i < locations.length; i++) {
                var currentHotspot = {
                  'objectId': locations[i].id,
                  'location': locations[i].get('location'),
                  'tag': locations[i].get('tag'),
                  'preference': preferenceDict[locations[i].get('tag')],
                  'archived': locations[i].get('archived')
                };

                currentHotspot.distance = getDistance(currentLocation,
                                                      currentHotspot.location);
                currentHotspot.distance = Math.round(currentHotspot.distance);

                // check if user has already been notified for the location
                var hotspotPrevNotified = false;
                if (prevNotificationLen > 0) {
                  for (var j = 0; j < prevNotificationLen; j++) {
                    var currentHotpotId = prevNotifications[j].get('hotspotId');
                    if (currentHotpotId == currentHotspot.objectId) {
                      hotspotPrevNotified = true;
                      break;
                    }
                  }
                }

                // check if user is one who initially marked it
                var didUserCreateLocation = false;
                if (locations[i].get('vendorId') == request.params.vendorId) {
                  didUserCreateLocation = true;
                }

                // check if current hotspot is archived from previous responses
                var isArchived = currentHotspot.archived;

                // push hotspot to array if conditions are met
                if (!hotspotPrevNotified && !didUserCreateLocation &&
                    !isArchived) {
                  distanceToHotspots.push(currentHotspot);
                }
              }

              distanceToHotspots.sort(sortBy('distance', {
                name: 'preference', primer: parseInt, reverse: false
              }));

              var topHotspots = distanceToHotspots;
              if (typeof request.params.count != 'undefined') {
                topHotspots = distanceToHotspots.slice(0, request.params.count);
              }

              var hotspotList = [];
              for (var k = 0; k < topHotspots.length; k++) {
                hotspotList.push(topHotspots[k].objectId);
              }

              var hotspotQuery = new Parse.Query('hotspot');
              hotspotQuery.containedIn('objectId', hotspotList);

              hotspotQuery.find({
                success: function (selectedHotspots) {
                  response.success(selectedHotspots);
                },
                error: function (error) {
                  /*jshint ignore:start*/
                  console.log(error);
                  /*jshint ignore:end*/
                }
              });
            },
            error: function (error) {
              /*jshint ignore:start*/
              console.log(error);
              /*jshint ignore:end*/
            }
          });
        },
        error: function (error) {
          /*jshint ignore:start*/
          console.log(error);
          /*jshint ignore:end*/
        }
      });
    },
    error: function (error) {
      /*jshint ignore:start*/
      console.log(error);
      /*jshint ignore:end*/
    }
  });
});

// Haversine formula for getting distance in miles.
var getDistance = function (p1, p2) {
  var R = 6378137; // Earth’s mean radius in meter
  var degToRad = Math.PI / 180; // Degree to radian conversion.

  var dLat = (p2.latitude - p1.latitude) * degToRad;
  var dLong = (p2.longitude - p1.longitude) * degToRad;

  var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(p1.latitude * degToRad) * Math.cos(p2.latitude * degToRad) *
      Math.sin(dLong / 2) * Math.sin(dLong / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c; // d = distance in meters

  return d;
};

var getRankForCategory = function (category, preferences) {
  if (preferences.firstPreference == category) {
    return 1;
  } else if (preferences.secondPreference == category) {
    return 2;
  } else if (preferences.thirdPreference == category) {
    return 3;
  } else if (preferences.fourthPreference == category) {
    return 4;
  } else {
    return 0;
  }
};

/*jshint ignore:start*/
// multicolumn sorting function
// from: http://stackoverflow.com/questions/6913512/how-to-sort-an-array-of-objects-by-multiple-fields
/*jshint ignore:end*/

var sortBy;

(function() {
    // utility functions
    var defaultCmp = function(a, b) {
            if (a == b)  {
              return 0;
            }
            return a < b ? -1 : 1;
        },
        getCmpFunc = function(primer, reverse) {
            var dfc = defaultCmp, // closer in scope
                cmp = defaultCmp;
            if (primer) {
                cmp = function(a, b) {
                    return dfc(primer(a), primer(b));
                };
            }
            if (reverse) {
                return function(a, b) {
                    return -1 * cmp(a, b);
                };
            }
            return cmp;
        };

    // actual implementation
    sortBy = function() {
        var fields = [],
            nFields = arguments.length,
            field, name, reverse, cmp;

        // preprocess sorting options
        for (var i = 0; i < nFields; i++) {
            field = arguments[i];
            if (typeof field === 'string') {
                name = field;
                cmp = defaultCmp;
            }
            else {
                name = field.name;
                cmp = getCmpFunc(field.primer, field.reverse);
            }
            fields.push({
                name: name,
                cmp: cmp
            });
        }

        // final comparison function
        return function(A, B) {
            var a, b, name, result;
            for (var i = 0; i < nFields; i++) {
                result = 0;
                field = fields[i];
                name = field.name;

                result = field.cmp(A[name], B[name]);
                if (result !== 0) {
                  break;
                }
            }
            return result;
        };
    };
}());
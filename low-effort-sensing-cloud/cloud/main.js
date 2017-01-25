// aggregates data and archives locations if they are no longer valid
Parse.Cloud.afterSave('pingResponse', function (request) {
  // thresholds for adding info and archiving hotspot
  var infoAddThreshold = 1;
  var archiveHotspotThreshold = 2;

  // get values from just saved object
  var responseId = request.object.id;
  var hotspotId = request.object.get('hotspotId');
  var question = request.object.get('question');
  var questionResponse = request.object.get('response');
  var timestamp = request.object.get('timestamp');

  // special cases --> don't save answer
  // "I don't know" for surprising things
  // "I don't come here regularly" for queues
  var responseExceptions = ['I don\'t know', 'I don\'t come here regularly',
                            'com.apple.UNNotificationDefaultActionIdentifier',
                            'com.apple.UNNotificationDismissActionIdentifier'];
  if (responseExceptions.indexOf(questionResponse) != -1) {
    return;
  }

  var getHotspotData = new Parse.Query('hotspot');
  getHotspotData.equalTo('objectId', hotspotId);
  getHotspotData.first({
    success: function (hotspotObject) {
      var saveTimes = hotspotObject.get('saveTimeForQuestion');
      var lastUpdateTimestamp = saveTimes[question];

      var responseForHotspot = new Parse.Query('pingResponse');
      responseForHotspot.equalTo('hotspotId', hotspotId);
      responseForHotspot.equalTo('question', question);
      responseForHotspot.greaterThanOrEqualTo('timestamp', lastUpdateTimestamp);
      responseForHotspot.find({
        success: function (hotspotResponses) {
          var similarResponseCount = 1;

          for (var i = 0; i < hotspotResponses.length; i++) {
            var currentResponse = hotspotResponses[i].get('response');

            if (currentResponse == questionResponse) {
              similarResponseCount++;
            }
          }

          if (similarResponseCount >= infoAddThreshold) {
            var newUpdateTimestamp = Math.round(Date.now() / 1000);
            var newInfo = hotspotObject.get('info');
            newInfo[question] = questionResponse;
            saveTimes[question] = newUpdateTimestamp;

            hotspotObject.set('saveTimeForQuestion', saveTimes);
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

// Set Archiver value before saving
Parse.Cloud.beforeSave('hotspot', function (request, response) {
  if (!request.object.get('archiver')) {
    request.object.set('archiver', '');
  }
  if (!request.object.get('beaconId')) {
    request.object.set('beaconId', '');
  }
  response.success();
});

// Archives old hotspots on either user response or system archive
Parse.Cloud.afterSave('hotspot', function (request) {
  var hotspot = request.object;
  var tag = hotspot.get('tag');
  var hotspotInfo = hotspot.get('info');
  var locationCommonName = hotspot.get('locationCommonName');

  // check if archived = true, if so stop
  if (hotspot.get('archived')) {
    return;
  }

  // check if any tracking terminators have been saved to info object
  var foodTerminators = {'isfood': 'no', 'foodtype': 'no food here',
                         'howmuchfood': 'none'};
  var queueTerminators = {'isline': 'no'};
  var spaceTerminators = {'isspace': 'no'};
  var surprisingTerminators = {'whatshappening': 'no',
                               'famefrom': 'no longer here',
                               'vehicles': 'no longer here',
                               'peopledoing': 'no longer here'};

  var terminatorsExist = false;
  switch (tag) {
    case 'food':
      terminatorsExist = checkForTerminators(foodTerminators, hotspotInfo);
      break;
    case 'queue':
      terminatorsExist = checkForTerminators(queueTerminators, hotspotInfo);
      break;
    case 'space':
      terminatorsExist = checkForTerminators(spaceTerminators, hotspotInfo);
      break;
    case 'surprising':
      terminatorsExist = checkForTerminators(surprisingTerminators,
                                             hotspotInfo);
      break;
    default:
      break;
  }

  if (terminatorsExist || hotspot.get('archiver') === 'system') {
    // archive old hotspot (user is archiver unless background job archives)
    hotspot.set('archived', true);
    if (hotspot.get('archiver') === '') {
      hotspot.set('archiver', 'user');
    }
    hotspot.save();

    // recreate pre-marked locations
    if (locationCommonName !== '') {
      // create new values for hotspot
      var timestamp = Math.round(Date.now() / 1000);
      var newInfo = JSON.parse(JSON.stringify(hotspotInfo));
      var newSaveTimes = JSON.parse(JSON.stringify(hotspotInfo));
      for (var i in hotspotInfo) {
        newInfo[i] = '';
        newSaveTimes[i] = timestamp;
      }

      // save new hotspot
      var parseHotspot = Parse.Object.extend('hotspot');
      var newHotspot = new parseHotspot();
      newHotspot.set('vendorId', '');
      newHotspot.set('tag', tag);
      newHotspot.set('info', newInfo);
      newHotspot.set('location', hotspot.get('location'));
      newHotspot.set('archived', false);
      newHotspot.set('archiver', '');
      newHotspot.set('timestampCreated', timestamp);
      newHotspot.set('gmtOffset', hotspot.get('gmtOffset'));
      newHotspot.set('timestampLastUpdate', timestamp);
      newHotspot.set('submissionMethod', '');
      newHotspot.set('locationCommonName', locationCommonName);
      newHotspot.set('saveTimeForQuestion', newSaveTimes);
      newHotspot.save();
    }
  }
});

var checkForTerminators = function (terminators, info) {
  for (var i in terminators) {
    if (info[i] == terminators[i]) {
      return true;
    }
  }

  return false;
};

// Background job to reset all locations after 12 hours if not already archived
Parse.Cloud.job('archiveOldHotspots', function (request, status) {
  // setup time thresholding variables
  var currentTime = Math.round(Date.now() / 1000);
  var thresholdAmount = 60 * 60 * 12; // 60s * 60m * 12hr
  var timeExpiryThreshold = currentTime - thresholdAmount;

  // fetch objects that are ready to be archived
  var hotspotQuery = new Parse.Query('hotspot');
  hotspotQuery.notEqualTo('archived', true);
  hotspotQuery.lessThan('timestampCreated', timeExpiryThreshold);
  hotspotQuery.each(function (hotspot) {
    hotspot.set('archiver', 'system');
    hotspot.save();
  }).then(function () {
    status.success('Routine archiving completed successfully.');
  }, function (error) {
    status.error('Routine archiving failed with error ' + error);
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
          locationQuery.limit(1000);
          locationQuery.notEqualTo('archived', true);

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
                    if (currentHotpotId === currentHotspot.objectId) {
                      hotspotPrevNotified = true;
                      break;
                    }
                  }
                }

                // check if user is one who initially marked it
                var didUserCreateLocation = false;
                if (locations[i].get('vendorId') === request.params.vendorId) {
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

// return closest n locations for tracking without preference weighting
Parse.Cloud.define('naivelyRetrieveLocationsForTracking', function(request, response) {
  var currentLocation = {
    'latitude': request.params.latitude,
    'longitude': request.params.longitude
  };
  var distanceToHotspots = [];

  var prevNotifiedQuery = new Parse.Query('notificationSent');
      prevNotifiedQuery.equalTo('vendorId', request.params.vendorId);
      prevNotifiedQuery.find({
        success: function (prevNotifications) {
          var prevNotificationLen = prevNotifications.length;

          // return locations sorted by distance and ranking for user
          var locationQuery = new Parse.Query('hotspot');
          locationQuery.limit(1000);
          locationQuery.notEqualTo('archived', true);

          locationQuery.find({
            success: function (locations) {
              for (var i = 0; i < locations.length; i++) {
                var currentHotspot = {
                  'objectId': locations[i].id,
                  'location': locations[i].get('location'),
                  'tag': locations[i].get('tag'),
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
                    if (currentHotpotId === currentHotspot.objectId) {
                      hotspotPrevNotified = true;
                      break;
                    }
                  }
                }

                // check if user is one who initially marked it
                var didUserCreateLocation = false;
                if (locations[i].get('vendorId') === request.params.vendorId) {
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

              distanceToHotspots.sort(function(a, b) {
                return (a.distance > b.distance) ? 1 : ((b.distance > a.distance) ? -1 : 0);
              });

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
  if (preferences.firstPreference === category) {
    return 1;
  } else if (preferences.secondPreference === category) {
    return 2;
  } else if (preferences.thirdPreference === category) {
    return 3;
  } else if (preferences.fourthPreference === category) {
    return 4;
  } else {
    return 0;
  }
};

// Get ranking for each user by contribution
// Weight primary contribute as 2x more than response to ping
Parse.Cloud.define('rankingsByContribution', function(request, response) {
  var userQuery = new Parse.Query('user');
  userQuery.find({
    success: function (users){
      var numberUsers = users.length;

      // convert users into object with location mark count and ping response count
      var userContribution = {};

      for (var i in users) {
        var currentUser = users[i];
        var displayName = currentUser.get('firstName').trim();
        displayName = displayName.concat(currentUser.get('lastName').trim().charAt(0));
        displayName = displayName.toLowerCase();
        if (displayName === '') {
          displayName = 'anonymous';
        }

        userContribution[currentUser.get('vendorId')] = {
          'displayName': displayName,
          'locationsMarked': 0,
          'notificationResponses': 0,
          'totalScore': 0
        };
      }

      // grab notification responses and aggregate for user
      var notificationResponseQuery = new Parse.Query('pingResponse');
      notificationResponseQuery.find({
        success: function (notificationResponses) {
          var notificationResponsesLen = notificationResponses.length;
          for(var i in notificationResponses) {
            var currentVendorId = notificationResponses[i].get('vendorId');
            userContribution[currentVendorId].notificationResponses += 1;
            userContribution[currentVendorId].totalScore += 1;
          }

          // grab hotspots and aggregate for user
          var locationQuery = new Parse.Query('hotspot');
          locationQuery.limit(1000);
          locationQuery.find({
            success: function (locations) {
              var locationCount = locations.length;
              for (var i in locations) {
                var currentVendorId = locations[i].get('vendorId');
                if (currentVendorId !== '') {
                  userContribution[currentVendorId].locationsMarked += 1;
                  userContribution[currentVendorId].totalScore += 2;
                }
              }

              // convert userContribution into array
              var leaderBoard = [];
              for(var key in userContribution) {
                  leaderBoard.push(userContribution[key]);
              }

              // order by total score
              leaderBoard.sort(function(a,b) {
                return (a.totalScore < b.totalScore) ? 1 : ((b.totalScore < a.totalScore) ? -1 : 0);
              });

              response.success(leaderBoard);
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

Parse.Cloud.define('fetchUserProfileData', function(request, response) {
  var output = {
    'username': '',
    'initials': '',
    'contributionCount': 0,
    'markedLocationCount': 0,
    'peopleHelped': 5,
    'contributionLocations': []
  };

  var userQuery = new Parse.Query('user');
  userQuery.equalTo('vendorId', request.params.vendorId);
  userQuery.find({
    success: function (users) {
      if (users.length > 0) {
        // parse out username and initials
        var currentUser = users[0];
        var username = currentUser.get('firstName').trim();
        var initials = '';
        username = username.concat(currentUser.get('lastName').trim().charAt(0));
        username = username.toLowerCase();
        if (username === '') {
          username = 'anonymous';
          initials = 'AN';
        } else {
          initials = currentUser.get('firstName').trim().charAt(0);
          initials = initials.concat(currentUser.get('lastName').trim().charAt(0));
          initials = initials.toUpperCase();
        }
        output.username = username;
        output.initials = initials;

        var responseQuery = new Parse.Query('pingResponse');
        responseQuery.equalTo('vendorId', request.params.vendorId);
        responseQuery.descending('timestamp');
        responseQuery.find({
          success: function (responses) {
            // contribution count and contributions where user has responded to notifications
            var contributionHotspots = [];
            var contribLocationList = [];

            if (responses.length > 0) {
              output.contributionCount = responses.length;
              for (var i in responses) {
                var newContributionLocation = {
                  'category': responses[i].get('tag').trim(),
                  'timestamp': responses[i].get('timestamp') + responses[i].get('gmtOffset'),
                  'contributionType': 'response',
                  'hotspotId': responses[i].get('hotspotId')
                };

                contributionHotspots.push(responses[i].get('hotspotId'));
                contribLocationList.push(newContributionLocation);
              }
            } else {
              output.contributionCount = 0;
            }

            // get locations for contributionLocations and any marked locations
            var genLocationQuery = new Parse.Query('hotspot');
            var contributionLocationQuery = new Parse.Query('hotspot');
            genLocationQuery.equalTo('vendorId', request.params.vendorId);
            contributionLocationQuery.containedIn('objectId', contributionHotspots);

            var mainQuery = new Parse.Query.or(genLocationQuery, contributionLocationQuery);
            mainQuery.descending('timestampCreated');
            mainQuery.find({
              success: function (hotspots) {
                if (hotspots.length > 0) {
                  for (var j in hotspots) {
                    if (hotspots[j].get('vendorId') === request.params.vendorId) {
                      var newMarkedLocation = {
                        'category': hotspots[j].get('tag').trim(),
                        'timestamp': hotspots[j].get('timestampCreated') +
                                     hotspots[j].get('gmtOffset'),
                        'contributionType': 'marked',
                        'hotspotId': hotspots[j].get('hotspotId'),
                        'latitude': hotspots[j].get('location').latitude,
                        'longitude': hotspots[j].get('location').longitude,
                      };

                      output.contributionLocations.push(newMarkedLocation);
                      output.markedLocationCount++;
                    } else {
                      for (var k in contribLocationList) {
                        if (contribLocationList[k].hotspotId === hotspots[j].id) {
                          contribLocationList[k].latitude = hotspots[i].get('location').latitude;
                          contribLocationList[k].longitude = hotspots[i].get('location').longitude;

                          output.contributionLocations.push(contribLocationList[k]);
                        }
                      }
                    }
                  }
                } else {
                  output.markedLocationCount = 0;
                }

                response.success(output);
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
      } else {
        output.username = 'anonymous';
        output.initials = 'AN';
        output.ranking = 0;
        output.contributionCount = 0;
        output.markedLocationCount = 0;
        output.peopleHelped = 0;

        response.success(output);
      }
    },
    error: function (error) {
      /*jshint ignore:start*/
      console.log(error);
      /*jshint ignore:end*/
    }
  });
});

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
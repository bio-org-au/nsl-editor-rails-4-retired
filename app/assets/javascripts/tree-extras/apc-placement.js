
function searchResultFocusApniPlacementTab(event, tr) {
//    console.log("ok! let's do apni nav!");
}

function searchResultFocusApcPlacementTab(event, tr) {
//    console.log("ok! let's do apc nav!");
}

var treeTabApp = angular.module('au.org.biodiversity.nsl.editor.apc-tree-placement', ['ui.bootstrap']);

// this function is used to declare that the html is ok

treeTabApp.filter("trustAsHtml", ['$sce', function($sce) {
    return function(htmlCode){
        return $sce.trustAsHtml(htmlCode);
    }
}]);

// create a sample directive

function SampleDirective() {
    return {
        template: "THIS IS A SAMPLE DIRECTIVE"
    };
}

treeTabApp.directive('sampledirective', SampleDirective);

function ApcTabController($scope, $http, $element, $sce) {
    $scope.instanceId = $element.data('instance-id');

    $scope.loading = true;
    $scope.loaded = false;
    $scope.error = false;
    $scope.data = null;

    $scope.treeLabel = 'APC'

    $scope.placeParams = {
        superName: null,
        apcStatus: null
    };

    $scope.removeParams = {
        replacementName: null
    };

    $scope.getLocation = function(val) {
        return $http.get(NSL_SUGGEST_URL + 'simpleName', {
            params: {
                term: val
            }
        }).then(function(response){
            return response.data;
        });
    };

    $scope.getApcName = function(val) {
        return $http.get(NSL_SUGGEST_URL + 'apc-search', {
            params: {
                term: val,
                instanceId: $scope.instanceId
            }
        }).then(function(response){
            return response.data;
        });

    }

    $scope.fetchPlacement = function() {
        $scope.loading = true;
        $scope.loaded = false;
        $scope.error = null;
        $scope.serviceException = null;

        $http.get(NSL_API_URL +'tree/instance-placement/' + $scope.treeLabel + '/' + $scope.instanceId,
            {
                transformResponse: function (data, headersGetter) {
                    try {
                        return JSON.parse(data);
                    }
                    catch (e) {
                        return data;
                    }
                }
            }
        )
            .success(function (data) {
                $scope.loading = false;
                $scope.loaded = true;
                $scope.data = data;
                $scope.preprocessData();
                $scope.reloadPlacementForm();

            })
            .error(function (data, status, headers, config) {
                console.log("we got an error {"
                + ",\nstatus: " + status
                + ",\nheaders: " + headers
                + ",\nconfig: " + config
                + "\n}");
                $scope.loaded = false;
                $scope.loading = false;
                $scope.error = data;
            });
    }

    $scope.preprocessData = function() {
        var data = this.data;
        // any pricessing that javascript needs to do, that only needs to be done once
        // after fetcing the data from the server
    }

    $scope.reloadPlacementForm = function() {
        $scope.error = null;
        $scope.serviceException = null;

        if($scope.data) {
            $scope.placeParams.superName = $scope.data.supernode ? $scope.data.supernode.name : null;
            $scope.placeParams.apcStatus = ($scope.data.node && $scope.data.node.type) ? ( $scope.data.node.type.idPart ? $scope.data.node.type.idPart : $scope.data.node.type.id ? $scope.data.node.type.id : 'ApcConcept' ) : 'ApcConcept';
        }
        else {
            $scope.placeParams.superName = null;
            $scope.placeParams.apcStatus = null;
        }
    }

    $scope.placeInApc = function() {
        $scope.loaded = false;
        $scope.loading = true;
        $scope.error = null;
        $scope.serviceException = null;

        $http.post(NSL_API_URL + 'tree/place-apc-instance', {
            instance: $scope.instanceId,
            supername: $scope.placeParams.superName ? $scope.placeParams.superName.id : null,
            placementType: $scope.placeParams.apcStatus,
        })
          .success(function(response){
            $scope.loading = false;
            $scope.loaded = true;

            if(response.success) {
                $scope.data = response;
                $scope.preprocessData();
                $scope.reloadPlacementForm();
            }
            else {
                $scope.serviceException = response.serviceException;
            }

        })
            .error(function (data, status, headers, config) {
                console.log("we got an error {"
                + ",\nstatus: " + status
                + ",\nheaders: " + headers
                + ",\nconfig: " + config
                + "\n}");
                $scope.loaded = false;
                $scope.loading = false;
                $scope.error = data;
            });
    }

    $scope.removeFromApc = function() {
        $scope.loaded = false;
        $scope.loading = true;
        $scope.error = null;
        $scope.serviceException = null;
        $http.post(NSL_API_URL + 'tree/remove-apc-instance', {
            instance: $scope.instanceId,
            replacementName: $scope.removeParams.replacementName ? $scope.removeParams.replacementName.id : null
        }).success(function(response){
            $scope.loading = false;
            $scope.loaded = true;

            if(response.success) {
                $scope.data = response;
                $scope.preprocessData();
                $scope.reloadPlacementForm();
            }
            else {
                $scope.serviceException = response.serviceException;
            }

        })
            .error(function (data, status, headers, config) {
                console.log("we got an error {"
                + ",\nstatus: " + status
                + ",\nheaders: " + headers
                + ",\nconfig: " + config
                + "\n}");
                $scope.loaded = false;
                $scope.loading = false;
                $scope.error = data;
            });
    }


    $scope.fetchPlacement();
}

ApcTabController.$inject = ['$scope', '$http', '$element', '$sce'];

treeTabApp.controller('apcTabController', ApcTabController);

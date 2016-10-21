alert("error removing name");

var json_result = {
    "success": false, "msg": [
        {
            "msg": "ServiceException: placeNameOnTree",
            "status": "danger",
            "body": "Cannot place name Doodia|70914 on tree UserArrangement|7994108",
            "nested": [
                {
                    "msg": "TODO",
                    "plainText": "TODO: Implement placeNameOnTree",
                    "message": "TODO: Implement placeNameOnTree",
                    "rawMessage": "TODO: {0}",
                    "args": [
                        "Implement placeNameOnTree"
                    ],
                    "nested": []
                }
            ]
        }
    ], "stackTrace": [
        {
            "file": "ServiceException.groovy",
            "line": 33,
            "method": "raise",
            "clazz": "au.org.biodiversity.nsl.tree.ServiceException"
        }, {
            "file": "UserWorkspaceManagerService.groovy",
            "line": 538,
            "method": "$tt__placeNameOnTree",
            "clazz": "au.org.biodiversity.nsl.tree.UserWorkspaceManagerService"
        }, {
            "file": "TreeEditController.groovy",
            "line": 216,
            "method": "doCall",
            "clazz": "au.org.biodiversity.nsl.api.TreeEditController$_$tt__placeNameOnTree_closure13"
        }, {
            "file": "TreeEditController.groovy",
            "line": 271,
            "method": "handleException",
            "clazz": "au.org.biodiversity.nsl.api.TreeEditController"
        }, {
            "file": "TreeEditController.groovy",
            "line": 215,
            "method": "$tt__placeNameOnTree",
            "clazz": "au.org.biodiversity.nsl.api.TreeEditController"
        }]
};

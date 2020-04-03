#!/usr/bin/env python
# coding=utf-8

from aliyunsdkcore.client import AcsClient
from aliyunsdkram.request.v20150501.ListUsersRequest import ListUsersRequest
from aliyunsdkram.request.v20150501.ListPoliciesForUserRequest import ListPoliciesForUserRequest
from aliyunsdkram.request.v20150501.ListGroupsForUserRequest import ListGroupsForUserRequest
from aliyunsdkram.request.v20150501.ListGroupsRequest import ListGroupsRequest
from aliyunsdkram.request.v20150501.ListPoliciesForGroupRequest import ListPoliciesForGroupRequest

import os
import json
import argparse


class RamClient:
    def __init__(self, client):
        self.client = client

    # 获取所有用户组信息
    def get_groups(self):
        # 构建ListGroups请求
        request = ListGroupsRequest()
        request.set_accept_format('json')
        # 发起请求，并得到response
        response = self.client.do_action_with_exception(request)
        groups = json.loads(response)['Groups']['Group']

        return groups

    # 获取所有用户组的权限信息
    def get_groups_with_policies(self):
        groups = self.get_groups()

        # 构建ListPoliciesForGroup请求
        request = ListPoliciesForGroupRequest()
        request.set_accept_format('json')

        for group in groups:
            request.set_GroupName(group['GroupName'])
            # 发起请求，并得到response
            response = self.client.do_action_with_exception(request)
            policies = json.loads(response)['Policies']['Policy']
            group['Policies'] = policies

        return groups

    # 获取用户的权限信息（不包含所属组中的权限）
    def get_user_policies(self, user_name):
        # 构建ListPoliciesForUser请求
        request = ListPoliciesForUserRequest()
        request.set_accept_format('json')
        # 设置请求参数
        request.set_UserName(user_name)
        # 发起请求，并得到response
        response = self.client.do_action_with_exception(request)
        policies = json.loads(response)['Policies']['Policy']

        return policies

    # 获取用户的用户组信息
    def get_groups_for_user(self, user_name):
        # 构建ListGroupsForUser请求
        request = ListGroupsForUserRequest()
        request.set_accept_format('json')
        # 设置请求参数
        request.set_UserName(user_name)
        response = self.client.do_action_with_exception(request)
        groups = json.loads(response)['Groups']['Group']

        return groups

    # 获取用户信息（不包含所属组）
    def get_users(self):
        # 构建ListUsers请求
        request = ListUsersRequest()
        request.set_accept_format('json')
        # 发起ListUsers请求，并得到response
        response = self.client.do_action_with_exception(request)
        users = json.loads(response)['Users']['User']

        return users

    # 获取用户及其所属组的信息
    def get_users_with_groups(self):
        users = self.get_users()

        for user in users:
            user_groups = self.get_groups_for_user(user['UserName'])
            user['Groups'] = user_groups

        return users


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--access-key',
        default=os.environ.get('ALICLOUD_ACCESS_KEY'),
        help='alicloud access key (default: "ALICLOUD_ACCESS_KEY" environ)')
    parser.add_argument(
        '--secret-key',
        default=os.environ.get('ALICLOUD_SECRET_KEY'),
        help='alicloud secret key (default: "ALICLOUD_SECRET_KEY" environ)')
    parser.add_argument(
        '--outfile',
        default='alicloud_user_info.json',
        help='file path for save alicloud user info (default: %(default)s)')
    return parser.parse_args()


if __name__ == '__main__':
    args = get_args()
    # 构建一个阿里云client，用于发起请求
    # 构建阿里云client时需要设置AccessKey ID和AccessKey Secret
    # RAM是Global Service，API入口位于华东 1（杭州），这里地域填写：cn-hangzhou
    client = AcsClient(args.access_key, args.secret_key, 'cn-hangzhou')
    ram_client = RamClient(client)

    groups = ram_client.get_groups_with_policies()
    users = ram_client.get_users_with_groups()

    for user in users:
        # 附加用户权限信息到用户信息中
        policies = ram_client.get_user_policies(user['UserName'])

        for user_group in user['Groups']:
            for group in groups:
                if user_group['GroupName'] == group['GroupName']:
                    policies.extend(group['Policies'])

        user['Policies'] = policies

    with open(args.outfile, 'w') as outfile:
        json.dump(users,
                  ensure_ascii=False,
                  indent=4,
                  sort_keys=True,
                  fp=outfile)

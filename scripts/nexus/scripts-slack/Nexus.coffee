#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

#Set of bot commands for nexus
#to create new nexus repository: create nexus repo test1
#to get details of repository:  print nexus repo test1
#to get list of all repositories: list nexus repos
#to create user with specific role: create nexus user testuser1 with any-all-view role
#to get details of user: print nexus user testuser1@cognizant.com
#to get list of all users: list nexus users
#to delete a nexus user: delete nexus user testuser1@cognizant.com
#to delete a nexus repository: delete nexus repo test1
#Env variables to set:
#	NEXUS_URL
#	NEXUS_USER_ID
#	NEXUS_PASSWORD
#	HUBOT_NAME
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


nexus_url = process.env.NEXUS_URL
nexus_user_id = process.env.NEXUS_USER_ID
nexus_password =  process.env.NEXUS_PASSWORD
botname = process.HUBOT_NAME
pod_ip = process.env.MY_POD_IP;

create_repo = require('./create_repo.js');
delete_repo = require('./delete_repo.js');
create_user = require('./create_user.js');
get_all_repo = require('./get_all_repo.js');
get_given_repo = require('./get_given_repo.js');
get_all_user = require('./get_all_user.js');
get_all_privileges = require('./get_all_privileges.js');
get_given_privilege = require('./get_given_privilege.js');
create_privilege = require('./create_privilege.js');
get_privileges_details = require('./get_privileges_details.js');
get_given_user = require('./get_given_user.js');
delete_user = require('./delete_user.js');
request = require('request');

readjson = require './readjson.js'
generate_id = require('./mongoConnt')
index = require('./index.js')

uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		dt = 'list nexus repos\nlist nexus users\nprint nexus repo <repo-id>\nprint nexus user <user-id>\ncreate nexus repo <repo-name>\ndelete nexus repo <repo-id>\ncreate nexus user <user-name> with <role-name> role\nshow artifacts in <groupId>\nlist nexus users\ndelete nexus user <user-id>\nlist nexus privileges\ncreate privilege <privilege name> <tagged repo id>';
		msg.send dt
		setTimeout (->index.passData dt),1000
	
	robot.router.post '/createnexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_repo.repo_create nexus_url, nexus_user_id, nexus_password, data_http.repoid, data_http.repo_name, (error, stdout, stderr) ->
				if error == null
					dt = 'Nexus repo created with ID : '.concat(data_http.repoid)
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus repo created'
					statusmsg = 'Success';
					dt = 'Nexus repo created with ID : '.concat(data_http.repoid)
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, dt
					setTimeout (->index.passData dt),1000
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	robot.respond /create nexus repo (.*)/i, (msg) ->
		message = msg.match[0]
		actionmsg = ""
		statusmsg = ""
		repoid = msg.match[1]
		repo_name = repoid
		unique_id = uniqueId(5);
		repoid = repoid.concat(unique_id);
		
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createnexusrepo.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.createnexusrepo.admin,podIp:pod_ip,message:msg.message.text,repoid:repoid,repo_name:repo_name,callback_id: 'createnexusrepo',tckid:tckid};
					data = {text: 'Approve Request for create nexus repo',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'createnexusrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.createnexusrepo.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.createnexusrepo.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_repo.repo_create nexus_url, nexus_user_id, nexus_password, repoid, repo_name, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus repo created'
						statusmsg= 'Success';
						dt = 'Nexus repo created with ID : '.concat(repoid)
						msg.send dt
						setTimeout (->index.passData dt),1000
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.router.post '/deletenexusrepo', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					actionmsg = 'Nexus repo deleted'
					statusmsg = 'Success';
					dt = 'Nexus repo deleted with ID : '.concat(data_http.repoid)
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					robot.messageRoom data_http.userid, dt
					setTimeout (->index.passData dt),1000
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	robot.respond /delete nexus repo (.*)/i, (msg) ->
		message =msg.match[0]
		actionmsg = ""
		statusmsg = ""
		repoid = msg.match[1]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.deletenexusrepo.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.deletenexusrepo.admin,podIp:pod_ip,message:msg.message.text,repoid:repoid,callback_id: 'deletenexusrepo',tckid:tckid};
					data = {text: 'Approve Request for delete nexus repo',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'deletenexusrepo',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.deletenexusrepo.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.deletenexusrepo.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_repo.repo_delete nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus repo deleted'
						statusmsg= 'Success';
						dt = 'Nexus repo deleted with ID : '.concat(repoid)
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexusreposome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, data_http.repoid, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	robot.respond /print nexus repo (.*)/i, (msg) ->
		repoid = msg.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusreposome.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.listnexusreposome.admin,podIp:pod_ip,message:msg.message.text,repoid:repoid,callback_id: 'listnexusreposome',tckid:tckid};
					data = {text: 'Approve Request for print nexus repo',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'listnexusreposome',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.listnexusreposome.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.listnexusreposome.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				get_given_repo.get_given_repo nexus_url, nexus_user_id, nexus_password, repoid, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	robot.router.post '/listnexusrepos', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	robot.respond /list nexus repos/i, (msg) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusrepos.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexusrepos.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexusrepos',tckid:tckid};
					data = {text: 'Approve Request for print nexus repo',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'listnexusrepos',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.listnexusrepos.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.listnexusrepos.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
				
			else
				get_all_repo.get_all_repo nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexususersome', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, data_http.userid_nexus, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	robot.respond /print nexus user (.*)/i, (msg) ->
		userid_nexus = msg.match[1]
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexususersome.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexususersome.admin,podIp:pod_ip,message:msg.message.text,userid_nexus:userid_nexus,callback_id: 'listnexususersome',tckid:tckid};
					data = {text: 'Approve Request for print nexus user',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'listnexususersome',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.listnexususersome.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.listnexususersome.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				get_given_user.get_given_user nexus_url, nexus_user_id, nexus_password, userid_nexus, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	robot.respond /list nexus users/i, (msg) ->
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.room,approver:stdout.listnexususer.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexususer',tckid:tckid};
					data = {text: 'Approve Request for print nexus users',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'listnexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.listnexususer.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.listnexususer.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				get_all_user.get_all_user nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/createnexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_user.create_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, data_http.roleid, data_http.password, (error, stdout, stderr) ->
				if error == null
					dt = 'Nexus user created with password : '.concat(data_http.password)
					setTimeout (->index.passData dt),1000
					actionmsg = 'Nexus user created';
					statusmsg = 'Success';
					dt = 'Nexus user created with password : '.concat(data_http.password)
					robot.messageRoom data_http.userid, dt
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
			
	robot.respond /create nexus user (.*) with (.*) role/i, (msg) ->
		message = msg.match[1]
		actionmsg = ""
		statusmsg = ""
		user_id = msg.match[1]
		roleid = msg.match[2]
		password = uniqueId(8);
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createnexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.createnexususer.admin,podIp:pod_ip,message:msg.message.text,user_id:user_id,roleid:roleid,password:password,callback_id: 'createnexususer',tckid:tckid};
					data = {text: 'Approve Request for create nexus user',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'createnexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid},{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.createnexususer.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.createnexususer.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				create_user.create_user nexus_url, nexus_user_id, nexus_password, user_id, roleid, password, (error, stdout, stderr) ->
					if error == null
						dt = 'Nexus user created with password : '.concat(password)
						actionmsg = 'Nexus user created';
						statusmsg= 'Success';
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/deletenexususer', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			delete_user.delete_user nexus_url, nexus_user_id, nexus_password, data_http.user_id, (error, stdout, stderr) ->
				if error == null
					actionmsg = 'Nexus user deleted'
					statusmsg = 'Success';
					dt = 'Nexus user deleted with ID : '.concat(data_http.user_id)
					robot.messageRoom data_http.userid, dt
					setTimeout (->index.passData dt),1000
					index.wallData botname, data_http.message, actionmsg, statusmsg;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	robot.respond /delete nexus user (.*)/i, (msg) ->
		message = msg.match[0]
		actionmsg = ""
		statusmsg = ""
		user_id = msg.match[1]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.deletenexususer.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.deletenexususer.admin,podIp:pod_ip,message:msg.message.text,user_id:user_id,callback_id: 'deletenexususer',tckid:tckid};
					data = {text: 'Approve Request for delete nexus user'+payload.user_id,attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'deletenexususer',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.deletenexususer.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.deletenexususer.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
					
			else
				delete_user.delete_user nexus_url, nexus_user_id, nexus_password, user_id, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus user deleted'
						statusmsg= 'Success';
						dt = 'Nexus user deleted with ID : '.concat(user_id)
						msg.send dt
						setTimeout (->index.passData dt),1000
						index.wallData botname, message, actionmsg, statusmsg;
					else
						msg.send error;
						setTimeout (->index.passData error),1000
						
	robot.router.post '/listnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
				if error == null
					setTimeout (->index.passData stdout),1000
					robot.messageRoom data_http.userid, stdout;
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			robot.messageRoom data_http.userid, 'You are not authorized.';
	robot.respond /list nexus privileges/i, (msg) ->
	
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.listnexusprivilege.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.listnexusprivilege.admin,podIp:pod_ip,message:msg.message.text,callback_id: 'listnexusprivilege',tckid:tckid};
					data = {text: 'Approve Request for see nexus privileges',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'listnexusprivilege',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.listnexusprivilege.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.listnexusprivilege.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
	
			else
				get_all_privileges.get_all_privileges nexus_url, nexus_user_id, nexus_password, (error, stdout, stderr) ->
					if error == null
						msg.send stdout;
						setTimeout (->index.passData stdout),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	robot.respond /get nexus privilege (.*)/i, (msg) ->
		userid = msg.match[1]
		get_given_privilege.get_given_privilege nexus_url, nexus_user_id, nexus_password, userid, (error, stdout, stderr) ->
			if error == null
				setTimeout (->index.passData stdout),1000
				msg.send stdout;
			else
				setTimeout (->index.passData error),1000
				msg.send error;
	robot.respond /search pri name (.*)/i, (msg) ->
		name = msg.match[1]
		msg.send name
		get_privileges_details.get_privileges_details nexus_url, nexus_user_id, nexus_password, name, (error, stdout, stderr) ->
			if error == null
				setTimeout (->index.passData stdout),1000
				msg.send stdout;
			else
				setTimeout (->index.passData error),1000
				msg.send error;
	
	robot.router.post '/createnexusprivilege', (request, response) ->
		data_http = if request.body.payload? then JSON.parse request.body.payload else request.body
		if data_http.action == 'Approve'
			create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, data_http.pri_name, data_http.repo_id, (error, stdout, stderr) ->
				if error == null
					actionmsg = 'Nexus privilege(s) created'
					statusmsg = 'Success'
					dt = stdout.concat(' with name : ').concat(data_http.pri_name).concat(' tagged with repo : ').concat(data_http.repo_id)
					robot.messageRoom data_http.userid, dt
					index.wallData botname, data_http.message, actionmsg, statusmsg;
					setTimeout (->index.passData dt),1000
				else
					setTimeout (->index.passData error),1000
					robot.messageRoom data_http.userid, error;
		else
			dt = 'You are not authorized.'
			robot.messageRoom data_http.userid, dt;
			setTimeout (->index.passData dt),1000
	
	robot.respond /create privilege (.*)/i, (msg) ->
		array_command = msg.match[1].split " ", 2
		pri_name = array_command[0]
		repo_id = array_command[1]
		message = msg.match[0]
		
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			if stdout.createnexusprivilege.workflowflag == true
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.id,approver:stdout.createnexusprivilege.admin,podIp:pod_ip,message:msg.message.text,repo_id:repo_id,pri_name:pri_name,callback_id: 'createnexusprivilege',tckid:tckid};
					data = {text: 'Approve Request for create nexus privilege',attachments: [{text: 'click yes to approve',fallback: 'Yes or No?',callback_id: 'createnexusprivilege',color: '#3AA3E3',attachment_type: 'default',actions: [{ name: 'Approve', text: 'Approve', type: 'button', value: tckid },{ name: 'Reject', text: 'Reject',  type: 'button',  value: tckid,confirm: {'title': 'Are you sure?','text': 'Do you want to Reject?','ok_text': 'Reject','dismiss_text': 'No'}}]}]}
					robot.messageRoom stdout.createnexusprivilege.adminid, data;
					msg.send 'Your approval request is waiting from '.concat(stdout.createnexusprivilege.admin);
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					generate_id.add_in_mongo dataToInsert
			else
				create_privilege.create_privilege nexus_url, nexus_user_id, nexus_password, pri_name, repo_id, (error, stdout, stderr) ->
					if error == null
						actionmsg = 'Nexus privilege(s) created'
						statusmsg = 'Success'
						dt = stdout.concat(' with name : ').concat(pri_name).concat(' tagged with repo : ').concat(repo_id);
						msg.send dt
						index.wallData botname, message, actionmsg, statusmsg;
						setTimeout (->index.passData dt),1000
					else
						msg.send error;
						setTimeout (->index.passData error),1000
	
	robot.respond /show artifacts in (.*)/i, (msg) ->
		url=nexus_url+'/service/local/lucene/search?g='+msg.match[1]+''
		options = {
		auth: {
		'user': nexus_user_id,
		'pass': nexus_password
		},
		method: 'GET',
		url: url
		}
		request options, (error, response, body) ->
			result = body.split('<artifact>')
			if(result.length==1)
				dt = 'No artifacts found for groupId: '+msg.match[1]
			else
				dt = '*No.*\t\t\t*Group Id*\t\t\t*Artifact Id*\t\t\t*Version*\t\t\t*Repo Id*\n'
				for i in [1...result.length]
					dt = dt + i+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\t\t\t'+result[i].split('<latestReleaseRepositoryId>')[1].split('</latestReleaseRepositoryId>')[0]+'\n'
			msg.send dt
			setTimeout (->index.passData dt),1000

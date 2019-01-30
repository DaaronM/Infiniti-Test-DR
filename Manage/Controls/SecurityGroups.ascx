<%@ Control Language="VB" AutoEventWireup="false" Inherits="Intelledox.Manage.Controls_SecurityGroups" Codebehind="SecurityGroups.ascx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<Controls:SecureCheckBoxList ID="chkGroups" runat="server" DataTextField="Name" DataValueField="GroupGuid">
</Controls:SecureCheckBoxList>
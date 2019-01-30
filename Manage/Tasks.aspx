<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Tasks" Codebehind="Tasks.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc1" TagName="ctlDate" Src="Controls/ctlDate.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <asp:Label ID="litProject" runat="server" Text="<%$Resources:Strings, Project%>" AssociatedControlID="txtProject"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtProject" runat="server"></asp:TextBox>
                            </td>
                            <td colspan="4"></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litUser" runat="server" Text="" AssociatedControlID="txtUser"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtUser" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Label ID="litLastName" runat="server" Text="<%$Resources:Strings, LastName%>" AssociatedControlID="txtLastName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtLastName" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Label ID="litFirstName" runat="server" Text="<%$Resources:Strings, FirstName%>" AssociatedControlID="txtFirstName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtFirstName" runat="server"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td style="width:125px">
                                <label for="txtFrom"><%:Resources.Strings.DateAssigned%> <%:Resources.Strings.From%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteFrom" TextboxId="txtFrom" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>
                            <td>
                                <label for="txtTo"><%:Resources.Strings.ToResource%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteTo" TextboxId="txtTo" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>
                            <td>
                                <asp:Button ID="btnSearch" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Search%>" />
                            </td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litIncludeTerminated" runat="server" Text="<%$Resources:Strings, IncludeTerminated %>" AssociatedControlID="chkIncludeTerminated" />
                            </td>
                            <td colspan="5">
                                <asp:CheckBox ID="chkIncludeTerminated" runat="server"></asp:CheckBox>
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="body">
                    <asp:GridView ID="grdTaskList" runat="server" Width="100%" AutoGenerateColumns="False" CssClass="grd" BorderWidth="0">
                        <Columns>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%#: GetAssignedToName("", Eval("OriginallyCreatedBy"), Intelledox.Model.TaskListStateAssignedType.User, Guid.Empty)%> 
                                    (<%#: Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("DateOriginallyCreatedUtc"), DateTime), "g")%>)
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%#: GetAssignedToName(Eval("AssignedTo"), Eval("AssignedGuid"), Eval("AssignedType"), Eval("LockedByUserGuid"))%> 
                                    (<%#: Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("DateCreatedUtc"), DateTime), "g")%>)
                                    <%# If(String.IsNullOrEmpty(Eval("Comment")),
                                            "",
                                            " <img src=""images/info.png"" title=""" & Resources.Strings.Comment & ": " & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Comment")) & """ />") %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# If(Eval("IsAborted") = 0,
                                                                    If(Eval("LockedByUserGuid") <> Guid.Empty AndAlso Eval("AssignedType") = Intelledox.Model.TaskListStateAssignedType.Group,
                                                                        "<img src=""Images/IX_Lock.svg"" title=""" & Resources.Strings.Locked & """ height=""16px""/><em> " & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("ProjectName")) & " (" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("StateName")) & ")</em>",
                                                                        Microsoft.Security.Application.Encoder.HtmlEncode(Eval("ProjectName")) & " (" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("StateName")) & ")"),
                                                                    "<span title=""" & Resources.Strings.Terminated & """><em>" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("ProjectName")) & " (" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("StateName")) & ")</em></span>")
                                    %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# "<a href='TaskHistory.aspx?ID=" & Eval("TaskListId").ToString() & "'><img src='Images/IX_History.svg' title='" & Resources.Strings.History & "' height='16' /></a>"
                                    %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# If(Eval("IsAborted") = 0,
                                            If(Eval("AssignedType") = Intelledox.Model.TaskListStateAssignedType.User,
                                            "<a href='Reassign.aspx?id=" & Eval("TaskListStateId").ToString() & "'>" & Resources.Strings.Reassign & "</a>",
                                                If(Eval("LockedByUserGuid") <> Guid.Empty,
                                                "<a href='Tasks.aspx?unlock=" & Eval("TaskListStateId").ToString() & "'>" & Resources.Strings.Unlock & "</a>",
                                                "")),
                                            "")
                                    %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# If(Eval("IsAborted") = 0,
                                         "<a href='Tasks.aspx?abort=" & Eval("TaskListStateId").ToString() & "' onclick=""return confirm('" & Resources.Strings.ConfirmTerminate & "');"">" & Resources.Strings.Terminate & "</a>",
                                         "")%>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoHistory %>" /></EmptyDataTemplate>
                    </asp:GridView>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
 </asp:Content>

